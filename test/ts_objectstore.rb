require 'dbi'
require 'date'
require 'lafcadio/mock'
require 'lafcadio/objectStore'
require 'lafcadio/query'
require 'lafcadio/test'
require 'runit/testcase'
require '../test/mock/domain'

class TestObjectStoreCache < LafcadioTestCase
	def setup
		super
		@cache = ObjectStore::Cache.new( MockDbBridge.new )
	end

	def test_clones
		user = User.getTestUser
		user.pk_id = 1
		@cache.save( user )
		assert( user.object_id != @cache.get( User, 1 ).object_id )
		@cache.get_all( User ).each { |a_user|
			assert( user.object_id != a_user.object_id )
		}
	end
	
	def test_dumpable
		cache_prime = Marshal.load( Marshal.dump( @cache ) )
		assert_equal( ObjectStore::Cache, cache_prime.class )
	end

	def testFlush
		user = User.getTestUser
		@cache.save(user)
		assert_equal 1, @cache.get_all(User).size
		@cache.flush(user)
		assert_equal 0, @cache.get_all(User).size
	end
end

class TestDBBridge < Test::Unit::TestCase
	include Lafcadio

  def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
    @mockDbh = MockDbh.new
		DbConnection.set_dbh( @mockDbh )
		@dbb = DbBridge.new
    @client = Client.new( {"pk_id" => 1, "name" => "clientName1"} )
  end

  def teardown
		@dbb = nil
 		DbConnection.flush
		DbConnection.set_db_name nil
	end

  def test_commits_delete
    @client.delete = true
    @dbb.commit(@client)
    assert_equal("delete from clients where pk_id=1", @mockDbh.lastSQL)
  end

  def testCommitsEdit
    @dbb.commit(@client)
    sql = @mockDbh.lastSQL
    assert(sql.index("update clients set name='clientName1'") != nil, sql)
  end

	def testCommitsForInheritedObjects
		ic = InternalClient.new({ 'pk_id' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		@dbb.commit ic
		assert_equal 2, @mockDbh.sql_statements.size
		sql1 = @mockDbh.sql_statements[0]
		assert_not_nil sql1 =~ /update clients set/, sql1
		sql2 = @mockDbh.sql_statements[1]
		assert_not_nil sql2 =~ /update internalClients set/, sql2
	end

	def testGetAll
		query = Query.new Domain::LineItem
		coll = @dbb.get_collection_by_query query
		assert_equal Array, coll.class
	end

	def test_group_query
		query = Query::Max.new( Client )
		assert_equal( 1, @dbb.group_query( query ).only )
		invoice = Invoice.storedTestInvoice
		query2 = Query::Max.new( Invoice, 'date' )
		assert_equal( invoice.date, @dbb.group_query( query2 ).only )
		query3 = Query::Max.new( XmlSku )
		assert_equal( 5, @dbb.group_query( query3 ).only )
	end

  def testLastPkIdInserted
    client = Client.new( { "name" => "clientName1" } )
    @dbb.commit client
    assert_equal 12, @dbb.last_pk_id_inserted
    DbConnection.flush
    DbConnection.set_dbh( @mockDbh )
		dbb2 = DbBridge.new
    assert_equal 12, dbb2.last_pk_id_inserted
  end
	
	def testLogsSql
		logFilePath = '../test/testOutput/sql'
		@dbb.execute_select( 'select * from users' )
		if FileTest.exist?( logFilePath )
			fail if Time.now - File.ctime( logFilePath ) < 5
		end
		LafcadioConfig.set_filename( '../test/testData/config_with_sql_logging.dat' )
		@dbb.execute_select( 'select * from clients' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
	
	def testLogsSqlToDifferentFileName
		LafcadioConfig.set_filename( '../test/testData/config_with_log_path.dat' )
		logFilePath = '../test/testOutput/another.sql'
		@dbb.execute_select( 'select * from users' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
	
	def test_passes_sql_value_converter_to_domain_class_init
		query = Query.new( XmlSku )
		xml_sku = @dbb.get_collection_by_query( query ).only
		assert_equal( 'foobar', xml_sku.text1 )
		assert_equal( 'foobar', xml_sku.text1 )
		assert_nil( xml_sku.date1 )
		assert_nil( xml_sku.date1 )
		assert_equal( DomainObjectProxy, xml_sku.link1.class )
		assert_equal( 1, xml_sku.link1.pk_id )
	end

  class MockDbh
  	@@connected = false
  
    attr_reader :lastSQL, :sql_statements
    
		def initialize
			@sql_statements = []
			@@connected = true
		end
		
		def do( sql, *binds )
			logSql( sql )
		end
		
		def logSql( sql )
      @lastSQL = sql
			@sql_statements << sql
		end

    def select_all(str)
			logSql( str )
      if str == "select last_insert_id()"
				[ { 'last_insert_id()' => '12' } ]
			elsif str == 'select max(pk_id) from clients'
				[ [ '1' ] ]
			elsif str == 'select max(date) from invoices'
				[ [ DBI::Date.new( 2001, 4, 5 ) ] ]
			elsif str == 'select * from some_other_table'
				[ OneTimeAccessHash.new( 'some_other_id' => '16',
				                         'text_one' => 'foobar', 'link1' => '1' ) ]
			elsif str == 'select max(some_other_id) from some_other_table'
				[ [ '5' ] ]
			else
				[]
      end
    end

    def get_all(object_type); []; end
    
    def disconnect
    	@@connected = false
    end
    
    def connected?
    	@@connected
    end
  end

	class OneTimeAccessHash < DelegateClass( Hash )
		attr_reader :key_lookups
	
		def initialize( hash )
			super( hash )
			@key_lookups = Hash.new( 0 )
		end
		
		def []( key )
			@key_lookups[key] += 1
			raise "Should only access #{ key } once" if @key_lookups[key] > 1
			super( key )
		end
	end
end

class TestDbConnection < Test::Unit::TestCase
	include Lafcadio

  def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
    @mockDbh = MockDbh.new
    DbConnection.set_dbh( @mockDbh )
  end

  def testConnectionPooling
  	DbConnection.set_connection_class( MockDbi )
    100.times { DbConnection.get_db_connection }
    DbConnection.flush
    DbConnection.set_connection_class( DBI )
  end

	def testDbName
  	DbConnection.set_connection_class( MockDbi )
  	DbConnection.flush
		MockDbi.flushInstanceCount
		ObjectStore.set_db_name 'some_other_db'
		db = DbBridge.new
		assert_equal 'some_other_db', MockDbi.dbName
    DbConnection.set_connection_class( DBI )
	end
	
	def testDisconnect
		DbConnection.get_db_connection.disconnect
		assert !@mockDbh.connected?
	end

  class MockDbh
  	@@connected = false
  
    attr_reader :lastSQL, :sql_statements
    
		def initialize
			@sql_statements = []
			@@connected = true
		end
		
		def do( sql, *binds )
			logSql( sql )
		end
		
		def logSql( sql )
      @lastSQL = sql
			@sql_statements << sql
		end

    def select_all(str)
			logSql( str )
      if str == "select last_insert_id()"
				[ { 'last_insert_id()' => '12' } ]
			elsif str == 'select max(pk_id) from clients'
				[ [ '1' ] ]
			elsif str == 'select max(date) from invoices'
				[ [ DBI::Date.new( 2001, 4, 5 ) ] ]
			elsif str == 'select * from some_other_table'
				[ OneTimeAccessHash.new( 'some_other_id' => '16', 'text1' => 'foobar',
				                         'link1' => '1' ) ]
      else
				[]
      end
    end

    def get_all(object_type); []; end
    
    def disconnect
    	@@connected = false
    end
    
    def connected?
    	@@connected
    end
  end

	class MockDbi
    @@instances = 0
    @@dbName = nil

		def MockDbi.connect( dbAndHost, user, password )
			@@dbName = dbAndHost.split(':')[2]
      @@instances += 1
      raise "initialize me just once, please" if @@instances > 1
      return MockDbh.new
		end

		def MockDbi.flushInstanceCount
			@@instances = 0
		end

		def MockDbi.dbName
			@@dbName
		end
  end
end

class TestDbObjectCommitter < LafcadioTestCase
	def setup
		super
		context = Context.instance
		context.flush
		@mockDBBridge = MockDbBridge.new
		@testObjectStore = ObjectStore.new( @mockDBBridge )
    ObjectStore.set_object_store @testObjectStore
	end
	
	def getFromDbBridge(object_type, pk_id)
		query = Query.new object_type, pk_id
		@mockDBBridge.get_collection_by_query(query)[0]
	end

	def testAssignsPkIdOnNewCommit
		client = Client.new({ 'name' => 'client name' })
		assert_nil client.pk_id
    committer = Committer.new(client, @mockDBBridge)
    committer.execute
		assert_not_nil client.pk_id
	end

	def testCommitType
		client = Client.new({ 'name' => 'client name' })
    committer = Committer.new(client, @mockDBBridge)
    committer.execute
		assert_equal Committer::INSERT, committer.commit_type
		client2 = Client.new({ 'pk_id' => 25, 'name' => 'client 25' })
		committer2 = Committer.new(client2, @mockDBBridge)
		committer2.execute
		assert_equal Committer::UPDATE, committer2.commit_type
		client2.delete = true
		committer3 = Committer.new(client2, @mockDBBridge)
		committer3.execute
		assert_equal Committer::DELETE, committer3.commit_type
	end
	
	def test_delete_cascade
		user = User.new( {} )
		user.commit
		assert( XmlSku.get_field( 'link1' ).delete_cascade )
		xml_sku = XmlSku.new( 'link1' => user )
		xml_sku.commit
		user.delete = true
		committer = Committer.new( user, @mockDBBridge )
		committer.execute
		assert_equal( 0, @testObjectStore.get_xml_skus.size )
	end

  def testDeleteSetsLinkFieldsToNil
		client = Client.new({ 'pk_id' => 1, 'name' => 'client name' })
		invoice = Invoice.new({ 'pk_id' => 1,
				'client' => DomainObjectProxy.new(client), 'date' => Date.new(2000, 1, 17),
				'rate' => 45, 'hours' => 20 })
    @mockDBBridge.commit client
    @mockDBBridge.commit invoice
    client.delete = true
    committer = Committer.new(client, @mockDBBridge)
    committer.execute
		assert_nil getFromDbBridge(Client, 1)
		assert_not_nil getFromDbBridge(Invoice, 1)
		assert_nil @testObjectStore.get(Invoice, 1).client
  end
end

class TestDomainComparable < LafcadioTestCase
	def testComparableToNil
		client = Client.storedTestClient
		assert( !( client == nil ) )
	end
end

class TestDomainObjectProxy < LafcadioTestCase
	def setup
		super
		@client = Client.storedTestClient
		@clientProxy = DomainObjectProxy.new(Client, 1)
		@clientProxy2 = DomainObjectProxy.new(Client, 2)
		@invoice = Invoice.storedTestInvoice
		@invoiceProxy = DomainObjectProxy.new(Invoice, 1)
	end

	def testCantInitializeWithAnotherProxy
		begin
			metaProxy = DomainObjectProxy.new( @clientProxy )
			fail "Should raise ArgumentError"
		rescue ArgumentError
			# ok
		end
	end

	def testComparisons
		assert @clientProxy == @client
		assert @client == @clientProxy
		assert @clientProxy < @clientProxy2
		assert @client < @clientProxy2
		assert @clientProxy != @invoiceProxy
	end

	def testEqlAndHash
		assert( @client.eql?(@clientProxy))
		assert( @clientProxy.eql?(@client))
		assert_equal(@mockObjectStore.get_client(1).hash, @clientProxy.hash)
	end
	
	def testFieldSettable
		@clientProxy.name = 'new client name'
		client = @clientProxy.get_db_object
		assert_equal( 'new client name', client.name )
	end

	def testGetDbObject
		assert_equal @client, @clientProxy.get_db_object
		begin
			@clientProxy2.get_db_object
			fail "should throw DomainObjectNotFoundError"
		rescue DomainObjectNotFoundError
			# ok
		end
	end

	def testInitFromDbObject
		clientProxyPrime = DomainObjectProxy.new(@client)
		assert @clientProxy == clientProxyPrime
	end

	def testMemberMethods
		assert_equal @client.name, @clientProxy.name
		assert_equal @invoice.name, @invoiceProxy.name
	end
end

class TestDomainObjectSqlMaker < LafcadioTestCase
  def testCantCommitInvalidObj
    client = Client.new( {} )
    client.error_messages << "Please enter a first name."
    caught = false
    begin
      DomainObjectSqlMaker.new(client).sql_statements[0]
    rescue DomainObjectInitError
      caught = true
    end
    assert caught
  end

  def testCommitSQLWithApostrophe
    client = Client.new( { "name" => "T'est name" } )
    assert_equal("T'est name", client.name)
    sql = DomainObjectSqlMaker.new(client).sql_statements[0][0]
    assert_equal("T'est name", client.name)
    assert_not_nil sql.index("'T''est name'"), sql
  end

  def testCommitSQLWithInvoice
    invoice = Invoice.new(
    	"client" => Client.getTestClient, "rate" => 70,
			"date" => Date.new(2001, 4, 5), "hours" => 36.5, "pk_id" => 1
		)
    update_sql = DomainObjectSqlMaker.new(invoice).sql_statements[0]
    assert_not_nil(update_sql =~ /update invoices/, update_sql)
    assert_not_nil(update_sql =~ /pk_id=1/, update_sql)
    invoice.delete = true
    deleteSQL = DomainObjectSqlMaker.new(invoice).sql_statements[0]
    assert_not_nil(deleteSQL =~ /delete from invoices where pk_id=1/)
  end

  def testFieldNamesForSQL
    sqlMaker = DomainObjectSqlMaker.new Invoice.getTestInvoice
    assert_equal( 6, sqlMaker.get_name_value_pairs( Invoice ).size )
  end
	
	def testInheritanceCommit
		ic = InternalClient.new({ 'pk_id' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		sqlMaker = DomainObjectSqlMaker.new ic
		statements = sqlMaker.sql_statements
		assert_equal 2, statements.size
		sql1 = statements[0]
		assert_not_nil sql1 =~ /update internalClients set/, sql1
		sql2 = statements[1]
		assert_not_nil sql2 =~ /update clients set/, sql2
	end

	def test_inheritance_insert
		ic = InternalClientDiffPk.new( 'name' => 'client name',
		                               'billingType' => 'trade' )
		sql_maker = DomainObjectSqlMaker.new( ic )
		statements = sql_maker.sql_statements
		assert_equal( 2, statements.size )
		sql1 = statements[0].first
		assert_match( /insert into clients/, sql1 )
		bind1 = statements[0].last
		assert_equal( 1, bind1.size )
		sql2 = statements[1].first
		assert_match( /insert into internalClients.*primary_key/, sql2 )
		assert_match( /values.*LAST_INSERT_ID\(\)/, sql2 )
		bind2 = statements[1].last
		assert_equal( 0, bind2.size )
	end

  def testInsertUpdateAndDelete
    values = { "name" => "ClientName1" }
    client1a = Client.new values
    insertSql = DomainObjectSqlMaker.new(client1a).sql_statements[0]
    values["pk_id"] = 1
    client1b = Client.new values
    updateSql = DomainObjectSqlMaker.new(client1b).sql_statements[0][0]
		assert_match( /update/, updateSql )
    assert_not_nil updateSql.index("pk_id")
    client1b.delete = true
    delete_sql = DomainObjectSqlMaker.new(client1b).sql_statements[0][0]
    assert_not_nil delete_sql.index("delete")
    assert_not_nil delete_sql.index("pk_id")
		binds = DomainObjectSqlMaker.new(client1b).sql_statements[0][1]
		assert_not_nil( binds )
		assert_equal( 0, binds.size )
  end

	def testSetsNulls
		client = Client.new({ 'pk_id' => 1, 'name' => 'client name',
				'referringClient' => nil, 'priorityInvoice' => nil })
		sqlMaker = DomainObjectSqlMaker.new client
		sql = sqlMaker.sql_statements[0]
		assert_not_nil sql =~ /referringClient=null/, sql
		assert_not_nil sql =~ /priorityInvoice=null/, sql
	end

	class InternalClientDiffPk < Client
		def self.get_class_fields; [ TextField.new( self, 'billingType' ) ]; end
		
		def self.sql_primary_key_name; 'primary_key'; end
		
		def self.table_name; 'internalClients'; end
	end
end

class TestGMockObjectStore < LafcadioTestCase
	def testAddsPkId
		@mockObjectStore.commit User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).pk_id
		@mockObjectStore.commit Client.new( { 'pk_id' => 10,
				'name' => 'client 10' } )
		assert_equal 'client 10', @mockObjectStore.get(Client, 10).name
		@mockObjectStore.commit Client.new( { 'pk_id' => 20,
				'name' => 'client 20' } )
		assert_equal 'client 20', @mockObjectStore.get(Client, 20).name
	end

	def testDelete
		user = User.getTestUser
		@mockObjectStore.commit user
		assert_equal 1, @mockObjectStore.get_all(User).size
		user.delete = true
		@mockObjectStore.commit user
		assert_equal 0, @mockObjectStore.get_all(User).size
	end

	def testDontChangeFieldsUntilCommit
		user = User.getTestUser
		user.commit
		user_prime = @mockObjectStore.get_user( 1 )
		assert( user.object_id != user_prime.object_id )
		new_email = "another@email.com"
		user_prime.email = new_email
		assert( new_email != @mockObjectStore.get_user( 1 ).email )
		user_prime.commit
		assert_equal( new_email, @mockObjectStore.get_user( 1 ).email )
	end

	def testObjectsRetrievable
		@mockObjectStore.commit User.getTestUser
		assert_equal 1, @mockObjectStore.get(User, 1).pk_id
	end

	def test_order_by
		client1 = Client.new( 'pk_id' => 1, 'name' => 'zzz' )
		client1.commit
		client2 = Client.new( 'pk_id' => 2, 'name' => 'aaa' )
		client2.commit
		query = Query.new Client
		query.order_by = 'name'
		clients = @mockObjectStore.get_subset( query )
		assert_equal( 2, clients.size )
		assert_equal( 'aaa', clients.first.name )
		assert_equal( 'zzz', clients.last.name )
		query2 = Query.new Client
		query2.order_by = 'name'
		query2.order_by_order = Query::DESC
		clients2 = @mockObjectStore.get_subset( query2 )
		assert_equal( 2, clients2.size )
		assert_equal( 'zzz', clients2.first.name )
		assert_equal( 'aaa', clients2.last.name )
	end

	def testRespectsLimit
		10.times { User.new({ 'firstNames' => 'John' }).commit }
		query = Query.new( User, Query::Equals.new( 'firstNames', 'John', User ) )
		query.limit = (1..5)
		assert_equal( 5, @mockObjectStore.get_subset( query ).size )
	end

	def testThrowsDomainObjectNotFoundError
		begin
			@mockObjectStore.get(User, 199)
			fail 'Should throw DomainObjectNotFoundError'
		rescue DomainObjectNotFoundError
			# ok
		end
	end

	def testUpdate
		@mockObjectStore.commit Client.new( { 'pk_id' => 100,
				'name' => 'client 100' } )
		assert_equal 'client 100', @mockObjectStore.get(Client, 100).name
		@mockObjectStore.commit Client.new( { 'pk_id' => 100,
				'name' => 'client 100.1' } )
		assert_equal 'client 100.1', @mockObjectStore.get(Client, 100).name
	end
end

class TestObjectStore < LafcadioTestCase
	def setup
		super
		context = Context.instance
		context.flush
		@mockDbBridge = MockDbBridge.new
		@testObjectStore = ObjectStore.new( @mockDbBridge )
		ObjectStore.set_object_store @testObjectStore
	end
	
	def setTestClient
		@client = Client.getTestClient
		@mockDbBridge.commit @client
	end

	def testCaching
		@testObjectStore.get_all Invoice
		assert_equal 0, @mockDbBridge.retrievals_by_type[Client]
		assert_equal 1, @mockDbBridge.retrievals_by_type[Invoice]
		@testObjectStore.get_all Invoice
		assert_equal 0, @mockDbBridge.retrievals_by_type[Client]
		assert_equal 1, @mockDbBridge.retrievals_by_type[Invoice]
		@testObjectStore.get_all Client
		assert_equal 1, @mockDbBridge.retrievals_by_type[Client]
	end

	def test_commit_returns_dobj
		client = Client.new({ 'name' => 'client name' })
		something = @testObjectStore.commit( client )
		assert_equal( Client, something.class )
	end

	def testConvertsFixnums
		@mockDbBridge.commit Client.getTestClient
		@testObjectStore.get Client, 1
		@testObjectStore.get Client, "1"
		begin
			@testObjectStore.get Client, "abc"
			fail "should throw exception for non-numeric index"
		rescue
			# ok
		end
	end

	def testDeepLinking
		client1 = Client.getTestClient
		@mockDbBridge.commit client1
		client1Proxy = DomainObjectProxy.new(Client, 1)
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2',
				'referringClient' => client1Proxy })
		@mockDbBridge.commit client2
		client2Prime = @testObjectStore.get_client 2
		assert_equal Client, client2Prime.referringClient.domain_class
	end

	def testDefersLoading
		@testObjectStore.get_all Invoice
		assert_equal 0, @mockDbBridge.retrievals_by_type[Client]
		assert_equal 1, @mockDbBridge.retrievals_by_type[Invoice]
	end

	def testDeleteClearsCachedValue
		client = Client.new({ 'pk_id' => 100, 'name' => 'client 100' })
		@testObjectStore.commit client
		assert_equal 1, @testObjectStore.get_all(Client).size
		client.delete = true
		@testObjectStore.commit client
		assert_equal 0, @testObjectStore.get_all(Client).size
	end

	def test_dispatches_inferred_query_to_collector
		setTestClient
		clients = @testObjectStore.get_clients { |client|
			client.name.equals( @client.name )
		}
	end
	
  def testDumpable
		newOs = Marshal.load(Marshal.dump(@testObjectStore))
    assert_equal ObjectStore, newOs.class
  end

	def testDynamicMethodNameDispatchingRaisesNoMethodError
		begin
			@testObjectStore.notAMethod
			raise "Should raise NoMethodError"
		rescue NoMethodError
			assert_match( /undefined method 'notAMethod'/, $!.to_s )
		end
		begin
			@testObjectStore.get_foo_bar
			raise "Should raise NoMethodError"
		rescue NoMethodError
			assert_match( /undefined method 'get_foo_bar'/, $!.to_s )
			# ok
		end
	end

	def testDynamicMethodNameDispatchesToCollectorMapObjectFunction
		option = TestOption.getTestOption
		@testObjectStore.commit option
		ili = TestInventoryLineItem.getTestInventoryLineItem
		@testObjectStore.commit ili
		ilio = TestInventoryLineItemOption.getTestInventoryLineItemOption
		@testObjectStore.commit ilio
		assert_equal( ili, ilio.inventory_line_item )
		assert_equal ilio, @testObjectStore.get_inventory_line_item_option(
				ili, option)
	end

	def testDynamicMethodNames
		setTestClient
		assert_equal @client, @testObjectStore.get_client(1)
		invoice1 = Invoice.new( 'client' => nil )
		invoice1.commit
		invoice2 = Invoice.new( 'client' => @client )
		invoice2.commit
		begin
			@testObjectStore.get_invoices( nil )
			raise "Should raise ArgumentError"
		rescue ArgumentError
			expected = "ObjectStore#get_invoices needs a field name as its second " +
			           "argument if its first argument is nil"
			assert_equal( expected, $!.to_s )
		end
		coll = @testObjectStore.get_invoices( nil, 'client' )
		assert_equal( invoice1, coll.only )
		xml_sku = XmlSku.new( 'pk_id' => 1 )
		xml_sku.commit
		user = User.getTestUserWithPkId
		xml_sku2 = XmlSku2.new( 'xml_sku' => xml_sku, 'link1' => user )
		xml_sku2.commit
		coll2 = @testObjectStore.get_xml_sku2s( xml_sku )
		assert_equal( xml_sku2, coll2.only )
		assert_equal( xml_sku2, @testObjectStore.get_xml_sku2s( user ).only )
	end

	def testDynamicMethodNamesAsFacadeForCollector
		setTestClient
		matchingClients = @testObjectStore.get_clients(@client.name, 'name')
		assert_equal 1, matchingClients.size
		assert_equal @client, matchingClients[0]
	end
	
	def testFlush
		client = Client.getTestClient
		@mockDbBridge.commit client
		assert_equal client.name, @testObjectStore.get(Client, 1).name
		client.name = 'new client name'
		@mockDbBridge.commit client
		assert_equal client.name, @testObjectStore.get(Client, 1).name
		@testObjectStore.flush client
		assert_equal 'new client name', @testObjectStore.get(Client, 1).name
	end

	def testFlushCacheAfterNewObjectCommit
		assert_equal 0, @testObjectStore.get_all(Client).size
		client = Client.new({ })
		@testObjectStore.commit client
		assert_equal 1, @testObjectStore.get_all(Client).size
	end
	
	def test_get_all_caches_for_later_subset_gets
		client = Client.getTestClient
		client.commit
		assert_equal( 1, @testObjectStore.get_all( Client ).size )
		assert_equal( 1, @mockDbBridge.query_count[ 'select * from clients' ])
		assert_equal( client, @testObjectStore.get_client( 1 ) )
		assert_equal(
			0,
			@mockDbBridge.query_count[
				'select * from clients where clients.pk_id = 1'
			]
		)
	end
	
	def testGetDbBridge
		assert_equal( @mockDbBridge, @testObjectStore.get_db_bridge )
	end
	
	def testGetInvoices
		client = Client.getTestClient
		client.commit
		inv1 = Invoice.new(
			'client' => client, 'date' => Date.today, 'rate' => 30, 'hours' => 40
		)
		@testObjectStore.commit inv1
		inv2 = Invoice.new(
			'client' => client, 'date' => Date.today - 7, 'rate' => 30, 'hours' => 40
		)
		@testObjectStore.commit inv2
		coll = @testObjectStore.get_invoices(client)
		assert_equal 2, coll.size
	end

	def testGetMapObject
		ili = TestInventoryLineItem.storedTestInventoryLineItem
		option = TestOption.storedTestOption
		iliOption = TestInventoryLineItemOption.storedTestInventoryLineItemOption
		assert_equal 1, @testObjectStore.get_all(InventoryLineItemOption).size
		assert_equal iliOption, @testObjectStore.get_map_object(InventoryLineItemOption,
				ili, option)
		begin
			@testObjectStore.get_map_object InventoryLineItemOption, ili, nil
			fail 'Should throw an error'
		rescue ArgumentError
			errorStr = $!.to_s
			assert_equal "ObjectStore#get_map_object needs two non-nil keys", errorStr
		end 
	end
	
	def test_get_mapped
		ili = TestInventoryLineItem.storedTestInventoryLineItem
		option = TestOption.storedTestOption
		iliOption = TestInventoryLineItemOption.storedTestInventoryLineItemOption
		collection = @testObjectStore.get_mapped( ili, 'Option' )
		assert_equal( 1, collection.size )
		option_prime = collection.first
		assert_equal( Option, option_prime.domain_class )
		assert_equal( option, option_prime )
	end

	def testGetObjects
		@testObjectStore.commit Client.new( { "pk_id" => 1, "name" => "clientName1" } )
		@testObjectStore.commit Client.new( { "pk_id" => 2, "name" => "clientName2" } )
		coll = @testObjectStore.get_objects(Client, [ 1, 2 ])
		assert_equal 2, coll.size
		foundOne = false
		foundTwo = false
		coll.each { |obj|
			foundOne = true if obj.pk_id == 1
			foundTwo = true if obj.pk_id == 2
		}
		assert foundOne
		assert foundTwo
		assert_raise( ArgumentError ) {
			@testObjectStore.get_objects(Client, [ "1", "2" ])
		}
		assert_raise( ArgumentError ) {
			@testObjectStore.get_objects( Client, 1 )
		}
	end

	def testGetSubset
		setTestClient
		condition = Query::Equals.new 'name', 'clientName1', Client
		query = Query.new Client, condition
		assert_equal @client, @testObjectStore.get_subset(condition)[0]
		assert_equal( 1, @mockDbBridge.query_count[query.to_sql])
		assert_equal @client, @testObjectStore.get_subset(query)[0]
		assert_equal( 1, @mockDbBridge.query_count[query.to_sql])
		query2 = Query.new( Client, Query::Equals.new( 'name', 'foobar', Client ) )
		assert_equal( 0, @testObjectStore.get_subset( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count[query2.to_sql])
		assert_equal( 0, @testObjectStore.get_subset( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count[query2.to_sql])
		query2_prime = Query.new(
			Client, Query::Equals.new( 'name', 'foobar', Client )
		)
		assert_equal( 0, @testObjectStore.get_subset( query2_prime ).size )
		assert_equal( 1, @mockDbBridge.query_count[query2_prime.to_sql])
	end

	def testGetWithaNonLinkingField	
		client = Client.getTestClient
		@testObjectStore.commit client
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2' })
		@testObjectStore.commit client2
		assert_equal 2, @testObjectStore.get_clients('client 2', 'name')[0].pk_id
	end

	def testHandlesLinksThroughProxies
		invoice = Invoice.storedTestInvoice
		origClient = @testObjectStore.get(Client, 1)
		assert_equal Client, origClient.class
		clientProxy = invoice.client
		assert_equal DomainObjectProxy, clientProxy.class
		matches = @testObjectStore.get_invoices(clientProxy)
		assert_equal 1, matches.size
	end

	def testMax
		setTestClient
		assert_equal 1, @testObjectStore.get_max(Client)
		Invoice.storedTestInvoice
		assert_equal( 70, @testObjectStore.get_max( Invoice, 'rate' ) )
		xml_sku = XmlSku.new( 'pk_id' => 25 )
		xml_sku.commit
		assert_equal( 25, @testObjectStore.get_max( XmlSku ) )
	end

	def test_method_missing
		begin
			@testObjectStore.get_foo_bar
			raise "Should raise NoMethodError"
		rescue NoMethodError
			# okay
		end
	end

	def test_query_field_comparison
		inv1 = Invoice.new( 'date' => Date.today, 'paid' => Date.today + 30 )
		inv1.commit
		inv2 = Invoice.new( 'date' => Date.today, 'paid' => Date.today )
		inv2.commit
		matches = @testObjectStore.get_invoices { |inv|
			inv.date.equals( inv.paid )
		}
		assert_equal( 1, matches.size )
	end

	def test_query_inference
		client1 = Client.new( 'pk_id' => 1, 'name' => 'client 1' )
		client1.commit
		client2 = Client.new( 'pk_id' => 2, 'name' => 'client 2' )
		client2.commit
		client3 = Client.new( 'pk_id' => 3, 'name' => 'client 3' )
		client3.commit
		coll1 = @testObjectStore.get_clients { |client| client.name.equals( 'client 1' ) }
		assert_equal( 1, coll1.size )
		assert_equal( 1, coll1[0].pk_id )
		coll2 = @testObjectStore.get_clients { |client| client.name.like( /^clie/ ) }
		assert_equal( 3, coll2.size )
		coll3 = @testObjectStore.get_clients { |client| client.name.like( /^clie/ ).not }
		assert_equal( 0, coll3.size )
		begin
			@testObjectStore.get_clients( 'client 1', 'name' ) { |client|
				client.name.equals( 'client 1' ).not
			}
			raise "Should raise ArgumentError"
		rescue ArgumentError
			# okay
		end
		coll4 = @testObjectStore.get_clients
		assert_equal( 3, coll4.size )
	end
	
	def test_raises_error_with_querying_with_uncommitted_dobj
		uncommitted = Client.new( {} )
		assert_raise( ArgumentError ) {
			@testObjectStore.get_invoices( uncommitted )
		}
	end

	def testRaisesExceptionIfCantFindObject
		begin
			@testObjectStore.get Client, 1
			fail "should throw exception for unfindable object"
		rescue DomainObjectNotFoundError
			# ok
		end
	end
	
	def test_respond_to?
		[ :get_client, :get_clients ].each { |meth_id|
			assert( @testObjectStore.respond_to?( meth_id ) )
		}
		[ :get_foo_bar, :foo_bar ].each { |meth_id|
			assert( !@testObjectStore.respond_to?( meth_id ) )
		}
	end
	
	def testSelfLinking
		client1Proxy = DomainObjectProxy.new(Client, 1)
		client2Proxy = DomainObjectProxy.new(Client, 2)
		client1 = Client.new({ 'pk_id' => 1, 'name' => 'client 1',
														'standard_rate' => 50,
														'referringClient' => client2Proxy })
		@mockDbBridge.commit client1
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2',
														'standard_rate' => 100,
														'referringClient' => client1Proxy })
		@mockDbBridge.commit client2
		client1Prime = @testObjectStore.get_client 1
		assert_equal 2, client1Prime.referringClient.pk_id
		assert_equal 100, client1Prime.referringClient.standard_rate
	end

	def testUpdateFlushesCache
		client = Client.new({ 'pk_id' => 100, 'name' => 'client 100' })
		@testObjectStore.commit client
		assert_equal 'client 100', @testObjectStore.get(Client, 100).name
		clientPrime = Client.new({ 'pk_id' => 100, 'name' => 'client 100.1' })
		@testObjectStore.commit clientPrime
		assert_equal 'client 100.1', @testObjectStore.get(Client, 100).name
		clientPrime.name = 'client 100.2'
		@testObjectStore.commit clientPrime
		assert_equal 'client 100.2', @testObjectStore.get(Client, 100).name		
	end
end

class TestSqlValueConverter < LafcadioTestCase
  def testConvertsPkId
    row_hash = { "pk_id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new(Client, row_hash)
    assert_equal(Fixnum, converter["pk_id"].class)
  end

	def test_different_db_field_name
		string = "Jane says I'm done with Sergio"
		svc = SqlValueConverter.new( XmlSku, { 'text_one' => string } )
		assert_equal( string, svc['text1'] )
	end

  def testExecute
    row_hash = { "id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = SqlValueConverter.new(Client, row_hash)
    assert_equal("clientName1", converter["name"])
    assert_equal(70, converter["standard_rate"])
  end

	def testInheritanceConstruction
		row_hash = { 'pk_id' => '1', 'name' => 'clientName1',
				'billingType' => 'trade' }
		objectHash = SqlValueConverter.new(InternalClient, row_hash)
		assert_equal 'clientName1', objectHash['name']
		assert_equal 'trade', objectHash['billingType']
	end

	def test_raises_if_bad_primary_key_match
		row_hash = { 'objId' => '1', 'name' => 'client name',
		             'standard_rate' => '70' }
		object_hash = SqlValueConverter.new( Client, row_hash )
		error_msg = 'The field "pk_id" can\'t be found in the table "clients".'
		assert_raise( FieldMatchError, error_msg ) { object_hash['pk_id'] }
	end

  def testTurnsLinkIdsIntoProxies
    row_hash = { "client" => "1", "date" => DBI::Date.new( 2001, 1, 1 ),
                "rate" => "70", "hours" => "40",
                "paid" => DBI::Date.new( 0, 0, 0 ) }
    converter = SqlValueConverter.new(Invoice, row_hash)
		assert_nil converter['clientId']
		assert_equal DomainObjectProxy, converter['client'].class
		proxy = converter['client']
		assert_equal 1, proxy.pk_id
		assert_equal Client, proxy.domain_class
  end
end
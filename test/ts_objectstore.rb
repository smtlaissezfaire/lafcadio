require 'dbi'
require 'date'
require 'lafcadio/mock'
require 'lafcadio/objectStore'
require 'lafcadio/query'
require 'lafcadio/test'
require 'runit/testcase'
require '../test/mock/domain'

class Lafcadio::ObjectStore
	attr_reader :cache
end

class TestObjectStoreCache < LafcadioTestCase
	def setup
		super
		@cache = @mockObjectStore.cache
	end

	def all( domain_class )
		q = Query.new domain_class
		@cache.get_by_query q
	end
	
	def testAssignsPkIdOnNewCommit
		client = Client.new({ 'name' => 'client name' })
		assert_nil client.pk_id
		@cache.commit client
		assert_not_nil client.pk_id
	end

	def test_clones
		user = User.getTestUser
		user.pk_id = 1
		@cache.save( user )
		assert( user.object_id != @cache.get( User, 1 ).object_id )
		all( User ).each do |a_user|
			assert( user.object_id != a_user.object_id )
		end
	end
	
	def test_delete_cascade
		user = User.new( {} )
		user.commit
		assert( XmlSku.field( 'link1' ).delete_cascade )
		xml_sku = XmlSku.new( 'link1' => user )
		xml_sku.commit
		user.delete = true
		@cache.commit user
		assert_equal( 0, @mockObjectStore.get_xml_skus.size )
	end

  def testDeleteSetsDomainObjectFieldsToNil
		client = Client.new( 'pk_id' => 1, 'name' => 'client name' )
		invoice = Invoice.new(
			'pk_id' => 1, 'client' => DomainObjectProxy.new( client ),
			'date' => Date.new( 2000, 1, 17 ), 'rate' => 45, 'hours' => 20
		)
		@cache.commit client
		@cache.commit invoice
    client.delete = true
		@cache.commit client
		assert_nil @cache[Client, 1]
		assert_not_nil @cache[Invoice, 1]
		assert_nil @cache[Invoice, 1].client
  end

	def test_dumpable
		cache_prime = Marshal.load( Marshal.dump( @cache ) )
		assert_equal( ObjectStore::Cache, cache_prime.class )
	end

	def testFlush
		user = User.getTestUser
		user.commit
		assert_equal( 1, all( User ).size )
		user.delete = true
		user.commit
		assert_equal( 0, all( User ).size )
	end

	def test_last_commit_type
		client = Client.new({ 'name' => 'client name' })
		@cache.commit client
		assert_equal( DomainObject::COMMIT_ADD, client.last_commit_type )
		client2 = Client.new({ 'pk_id' => 25, 'name' => 'client 25' })
		@cache.commit client2
		assert_equal( DomainObject::COMMIT_EDIT, client2.last_commit_type )
		client2.delete = true
		@cache.commit client2
		assert_equal(	DomainObject::COMMIT_DELETE, client2.last_commit_type )
	end
end

class TestCommitSqlStatementsAndBinds < LafcadioTestCase
  def testCommitSQLWithApostrophe
    client = Client.new( { "name" => "T'est name" } )
    assert_equal("T'est name", client.name)
    sql = ObjectStore::CommitSqlStatementsAndBinds.new(client)[0][0]
    assert_equal("T'est name", client.name)
    assert_not_nil sql.index("'T''est name'"), sql
  end

  def testCommitSQLWithInvoice
    invoice = Invoice.new(
    	"client" => Client.getTestClient, "rate" => 70,
			"date" => Date.new(2001, 4, 5), "hours" => 36.5, "pk_id" => 1
		)
    update_sql = ObjectStore::CommitSqlStatementsAndBinds.new(invoice)[0]
    assert_not_nil(update_sql =~ /update invoices/, update_sql)
    assert_not_nil(update_sql =~ /pk_id=1/, update_sql)
    invoice.delete = true
    deleteSQL = ObjectStore::CommitSqlStatementsAndBinds.new(invoice)[0]
    assert_not_nil(deleteSQL =~ /delete from invoices where pk_id=1/)
  end

  def testFieldNamesForSQL
    sqlMaker = ObjectStore::CommitSqlStatementsAndBinds.new Invoice.getTestInvoice
    assert_equal( 6, sqlMaker.get_name_value_pairs( Invoice ).size )
  end
	
	def testInheritanceCommit
		ic = InternalClient.new({ 'pk_id' => 1, 'name' => 'client name',
				'billingType' => 'trade' })
		statements = ObjectStore::CommitSqlStatementsAndBinds.new ic
		assert_equal 2, statements.size
		sql1 = statements[0]
		assert_not_nil sql1 =~ /update internalClients set/, sql1
		sql2 = statements[1]
		assert_not_nil sql2 =~ /update clients set/, sql2
	end

	def test_inheritance_insert
		cdo = ChildDomainObject.new(
			'parent_string' => 'parent string', 'child_string' => 'child string'
		)
		statements = ObjectStore::CommitSqlStatementsAndBinds.new( cdo )
		assert_equal( 2, statements.size )
		sql1 = statements[0].first
		assert_match( /insert into parent_domain_objects/, sql1 )
		bind1 = statements[0].last
		assert_equal( 1, bind1.size )
		sql2 = statements[1].first
		assert_match( /insert into table_name.*primary_key/, sql2 )
		assert_match( /values.*LAST_INSERT_ID\(\)/, sql2 )
		bind2 = statements[1].last
		assert_equal( 0, bind2.size )
	end

  def testInsertUpdateAndDelete
    values = { "name" => "ClientName1" }
    client1a = Client.new values
    insertSql = ObjectStore::CommitSqlStatementsAndBinds.new(client1a)[0]
    values["pk_id"] = 1
    client1b = Client.new values
    updateSql = ObjectStore::CommitSqlStatementsAndBinds.new(client1b)[0][0]
		assert_match( /update/, updateSql )
    assert_not_nil updateSql.index("pk_id")
    client1b.delete = true
    delete_sql = ObjectStore::CommitSqlStatementsAndBinds.new(client1b)[0][0]
    assert_not_nil delete_sql.index("delete")
    assert_not_nil delete_sql.index("pk_id")
		binds = ObjectStore::CommitSqlStatementsAndBinds.new(client1b)[0][1]
		assert_not_nil( binds )
		assert_equal( 0, binds.size )
  end

	def testSetsNulls
		client = Client.new({ 'pk_id' => 1, 'name' => 'client name',
				'referringClient' => nil, 'priorityInvoice' => nil })
		sql = ObjectStore::CommitSqlStatementsAndBinds.new( client )[0]
		assert_not_nil sql =~ /referringClient=null/, sql
		assert_not_nil sql =~ /priorityInvoice=null/, sql
	end

	class ParentDomainObject < Lafcadio::DomainObject
		string 'parent_string'
		blob   'blob'
	end
	
	class ChildDomainObject < ParentDomainObject
		string 'child_string'
				
		def self.sql_primary_key_name; 'primary_key'; end
		
		def self.table_name; 'table_name'; end
	end
end

class TestDBBridge < Test::Unit::TestCase
	include Lafcadio

  def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
    @mockDbh = MockDbh.new
		ObjectStore::DbConnection.set_dbh( @mockDbh )
		@dbb = ObjectStore::DbBridge.new
    @client = Client.new( {"pk_id" => 1, "name" => "clientName1"} )
  end

  def teardown
		@dbb = nil
 		ObjectStore::DbConnection.flush
		ObjectStore::DbConnection.set_db_name nil
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
		assert_match( /update internal_clients set/, sql2 )
	end

	def testGetAll
		query = Query.new Domain::LineItem
		coll = @dbb.collection_by_query query
		assert_equal Array, coll.class
	end

	def test_group_query
		query = Query::Max.new( Client )
		assert_equal( 1, @dbb.group_query( query ).only[:max] )
		invoice = Invoice.storedTestInvoice
		query2 = Query::Max.new( Invoice, 'date' )
		assert_equal( invoice.date, @dbb.group_query( query2 ).only[:max].to_date )
		query3 = Query::Max.new( XmlSku )
		assert_equal( 5, @dbb.group_query( query3 ).only[:max] )
		query4 = Query::Max.new( Attribute )
		assert_nil( @dbb.group_query( query4 ).only[:max] )
	end

  def testLastPkIdInserted
    client = Client.new( { "name" => "clientName1" } )
    @dbb.commit client
    assert_equal 12, @dbb.last_pk_id_inserted
    ObjectStore::DbConnection.flush
    ObjectStore::DbConnection.set_dbh( @mockDbh )
		dbb2 = ObjectStore::DbBridge.new
    assert_equal 12, dbb2.last_pk_id_inserted
  end
	
	def testLogsSql
		logFilePath = '../test/testOutput/sql'
		@dbb.execute_select( 'select * from users' )
		if FileTest.exist?( logFilePath )
			fail if Time.now - File.ctime( logFilePath ) < 5
		end
		LafcadioConfig.set_filename(
			'../test/testData/config_with_sql_logging.dat'
		)
		LafcadioConfig.set_values( nil )
		@dbb.execute_select( 'select * from clients' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
	
	def testLogsSqlToDifferentFileName
		LafcadioConfig.set_filename( '../test/testData/config_with_log_path.dat' )
		LafcadioConfig.set_values( nil )
		logFilePath = '../test/testOutput/another.sql'
		@dbb.execute_select( 'select * from users' )
		fail if Time.now - File.ctime( logFilePath ) > 5
	end
	
	def test_passes_sql_value_converter_to_domain_class_init
		query = Query.new( XmlSku )
		xml_sku = @dbb.collection_by_query( query ).only
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
				[ [ 1 ] ]
			elsif str == 'select max(date) from invoices'
				[ [ DBI::Date.new( 2001, 4, 5 ) ] ]
			elsif str == 'select * from some_other_table'
				[ OneTimeAccessHash.new( 'some_other_id' => '16',
				                         'text_one' => 'foobar', 'link1' => '1' ) ]
			elsif str == 'select max(some_other_id) from some_other_table'
				[ [ 5 ] ]
			elsif str == 'select max(pk_id) from attributes'
				[ [ nil ] ]
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
    ObjectStore::DbConnection.set_dbh( @mockDbh )
  end

  def testConnectionPooling
  	ObjectStore::DbConnection.set_connection_class( MockDbi )
    100.times { ObjectStore::DbConnection.get_db_connection }
    ObjectStore::DbConnection.flush
    ObjectStore::DbConnection.set_connection_class( DBI )
  end

	def testDbName
  	ObjectStore::DbConnection.set_connection_class( MockDbi )
  	ObjectStore::DbConnection.flush
		MockDbi.flushInstanceCount
		ObjectStore.db_name = 'some_other_db'
		db = ObjectStore::DbBridge.new
		assert_equal 'some_other_db', MockDbi.dbName
    ObjectStore::DbConnection.set_connection_class( DBI )
	end
	
	def testDisconnect
		ObjectStore::DbConnection.get_db_connection.disconnect
		assert !@mockDbh.connected?
	end

  class MockDbh
  	@@connected = false
  
    attr_reader :lastSQL, :sql_statements
    
		def initialize
			@sql_statements = []
			@@connected = true
		end
		
		def[]= ( key, val ); end
		
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
		client = @clientProxy.db_object
		assert_equal( 'new client name', client.name )
	end

	def testGetDbObject
		assert_equal @client, @clientProxy.db_object
		begin
			@clientProxy2.db_object
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
		context = ContextualService::Context.instance
		context.flush
		@testObjectStore = MockObjectStore.new
		@mockDbBridge = @testObjectStore.get_db_bridge
		ObjectStore.set_object_store @testObjectStore
	end
	
	def setTestClient
		@client = Client.getTestClient
		@mockDbBridge.commit @client
	end

	def testCaching
		@testObjectStore.get_all Invoice
		assert_equal( 0, @mockDbBridge.queries( Client ).size )
		assert_equal( 1, @mockDbBridge.queries( Invoice ).size )
		@testObjectStore.get_all Invoice
		assert_equal( 0, @mockDbBridge.queries( Client ).size )
		assert_equal( 1, @mockDbBridge.queries( Invoice ).size )
		@testObjectStore.get_all Client
		assert_equal( 1, @mockDbBridge.queries( Client ).size )
	end
	
	def test_commit_notifies_proxies_to_update_before_triggers
		client = Client.new( 'name' => 'Lovecraft' )
		client.commit
		invoice = Invoice.new( 'client' => client )
		invoice.commit
		client.priorityInvoice = invoice
		client.commit
		assert_equal( 'Lovecraft', client.priorityInvoice.client.name )
		assert_raise( RuntimeError ) do
			client.name = 'Cthulhu'
			client.commit
		end
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
		assert_equal( 0, @mockDbBridge.queries( Client ).size )
		assert_equal( 1, @mockDbBridge.queries( Invoice ).size )
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
    assert_equal MockObjectStore, newOs.class
  end

	def testDynamicMethodNameDispatchingRaisesNoMethodError
		begin
			@testObjectStore.notAMethod
			raise "Should raise NoMethodError"
		rescue NoMethodError
			assert_match( /undefined method `notAMethod'/, $!.to_s )
		end
		begin
			@testObjectStore.get_foo_bar
			raise "Should raise NoMethodError"
		rescue NoMethodError
			assert_match( /undefined method `get_foo_bar'/, $!.to_s )
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
		assert_equal( 1, @mockDbBridge.query_count( 'select * from clients' ) )
		assert_equal( client, @testObjectStore.get_client( 1 ) )
		assert_equal(
			0,
			@mockDbBridge.query_count(
				'select * from clients where clients.pk_id = 1'
			)
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
		assert_equal(
			1, @mockDbBridge.queries.select { |q| q.to_sql == query.to_sql }.size
		)
		assert_equal( 1, @mockDbBridge.query_count( query.to_sql ) )
		assert_equal @client, @testObjectStore.get_subset(query)[0]
		assert_equal( 1, @mockDbBridge.query_count( query.to_sql ) )
		query2 = Query.new( Client, Query::Equals.new( 'name', 'foobar', Client ) )
		assert_equal( 0, @testObjectStore.get_subset( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count( query2.to_sql ) )
		assert_equal( 0, @testObjectStore.get_subset( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count( query2.to_sql ) )
		query2_prime = Query.new(
			Client, Query::Equals.new( 'name', 'foobar', Client )
		)
		assert_equal( 0, @testObjectStore.get_subset( query2_prime ).size )
		assert_equal( 1, @mockDbBridge.query_count( query2_prime.to_sql ) )
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
			assert( @testObjectStore.respond_to?( meth_id ), meth_id )
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

class TestSqlToRubyValues < LafcadioTestCase
  def testConvertsPkId
    row_hash = { "pk_id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = ObjectStore::SqlToRubyValues.new(Client, row_hash)
    assert_equal(Fixnum, converter["pk_id"].class)
  end

	def test_different_db_field_name
		string = "Jane says I'm done with Sergio"
		svc = ObjectStore::SqlToRubyValues.new( XmlSku, { 'text_one' => string } )
		assert_equal( string, svc['text1'] )
	end

  def testExecute
    row_hash = { "id" => "1", "name" => "clientName1",
		"standard_rate" => "70" }
    converter = ObjectStore::SqlToRubyValues.new(Client, row_hash)
    assert_equal("clientName1", converter["name"])
    assert_equal(70, converter["standard_rate"])
  end

	def testInheritanceConstruction
		row_hash = { 'pk_id' => '1', 'name' => 'clientName1',
				'billingType' => 'trade' }
		objectHash = ObjectStore::SqlToRubyValues.new(InternalClient, row_hash)
		assert_equal 'clientName1', objectHash['name']
		assert_equal 'trade', objectHash['billingType']
	end

	def test_raises_if_bad_primary_key_match
		row_hash = { 'objId' => '1', 'name' => 'client name',
		             'standard_rate' => '70' }
		object_hash = ObjectStore::SqlToRubyValues.new( Client, row_hash )
		error_msg = 'The field "pk_id" can\'t be found in the table "clients".'
		assert_raise( FieldMatchError, error_msg ) { object_hash['pk_id'] }
	end

  def testTurnsLinkIdsIntoProxies
    row_hash = { "client" => "1", "date" => DBI::Date.new( 2001, 1, 1 ),
                "rate" => "70", "hours" => "40",
                "paid" => DBI::Date.new( 0, 0, 0 ) }
    converter = ObjectStore::SqlToRubyValues.new(Invoice, row_hash)
		assert_nil converter['clientId']
		assert_equal DomainObjectProxy, converter['client'].class
		proxy = converter['client']
		assert_equal 1, proxy.pk_id
		assert_equal Client, proxy.domain_class
  end
end
require 'dbi'
require 'date'
require 'lafcadio/mock'
require 'lafcadio/objectStore'
require 'lafcadio/query'
require 'lafcadio/test'
require 'runit/testcase'
require '../test/mock_domain'

class Lafcadio::ObjectStore
	attr_reader :cache
end

class MockDbi
	def self.connect( dbAndHost, user, password )
		@@db_name = dbAndHost.split(':')[2]
		@@instances += 1
		raise "initialize me just once, please" if @@instances > 1
		@@mock_dbh = MockDbh.new
	end

	def self.db_name; @@db_name; end
	
	def self.flush_instance_count; @@instances = 0; end

	def self.mock_dbh; @@mock_dbh; end
	
	def self.reset
		@@instances = 0
		@@db_name = nil
	end
	
	reset
	
	class MockDbh
  	@@connected = false

		attr_reader :sql_statements
		
		def initialize
			@sql_statements = []
			@@connected = true
		end

		def []= ( key, val ); end

    def connected?; @@connected; end

		def do( sql, *binds ); log_sql( sql ); end

    def disconnect; @@connected = false; end
    
		def log_sql( sql ); @sql_statements << sql; end

		def select_all(str)
			log_sql( str )
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

class TestDomainObjectProxy < LafcadioTestCase
	def setup
		super
		@client = Client.committed_mock
		@clientProxy = DomainObjectProxy.new(Client, 1)
		@clientProxy2 = DomainObjectProxy.new(Client, 2)
		@invoice = Invoice.committed_mock
		@invoiceProxy = DomainObjectProxy.new(Invoice, 1)
	end

	def test_cant_initialize_with_another_proxy
		begin
			metaProxy = DomainObjectProxy.new( @clientProxy )
			fail "Should raise ArgumentError"
		rescue ArgumentError
			# ok
		end
	end

	def test_comparisons
		assert @clientProxy == @client
		assert @client == @clientProxy
		assert @clientProxy < @clientProxy2
		assert @client < @clientProxy2
		assert @clientProxy != @invoiceProxy
	end

	def test_db_object
		assert_equal @client, @clientProxy.db_object
		begin
			@clientProxy2.db_object
			fail "should throw DomainObjectNotFoundError"
		rescue DomainObjectNotFoundError
			# ok
		end
	end

	def test_eql_and_hash
		assert( @client.eql?(@clientProxy))
		assert( @clientProxy.eql?(@client))
		assert_equal(@mockObjectStore.client(1).hash, @clientProxy.hash)
	end
	
	def test_field_settable
		@clientProxy.name = 'new client name'
		client = @clientProxy.db_object
		assert_equal( 'new client name', client.name )
	end

	def test_init_from_db_object
		clientProxyPrime = DomainObjectProxy.new(@client)
		assert @clientProxy == clientProxyPrime
	end

	def test_member_methods
		assert_equal @client.name, @clientProxy.name
		assert_equal @invoice.name, @invoiceProxy.name
	end
end

class TestObjectStore < LafcadioTestCase
	def setup
		super
		context = ContextualService::Context.instance
		context.flush
		@testObjectStore = MockObjectStore.new
		@mockDbBridge = @testObjectStore.db_bridge
		ObjectStore.set_object_store @testObjectStore
	end
	
	def set_test_client
		@client = Client.uncommitted_mock
		@mockDbBridge.commit @client
	end

	def test_all_caches_for_later_subset_gets
		client = Client.uncommitted_mock
		client.commit
		assert_equal( 1, @testObjectStore.all( Client ).size )
		assert_equal( 1, @mockDbBridge.query_count( 'select * from clients' ) )
		assert_equal( client, @testObjectStore.client( 1 ) )
		assert_equal(
			0,
			@mockDbBridge.query_count(
				'select * from clients where clients.pk_id = 1'
			)
		)
	end
	
	def test_caching
		@testObjectStore.all Invoice
		assert_equal( 0, @mockDbBridge.queries( Client ).size )
		assert_equal( 1, @mockDbBridge.queries( Invoice ).size )
		@testObjectStore.all Invoice
		assert_equal( 0, @mockDbBridge.queries( Client ).size )
		assert_equal( 1, @mockDbBridge.queries( Invoice ).size )
		@testObjectStore.all Client
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

	def test_converts_fixnums
		@mockDbBridge.commit Client.uncommitted_mock
		@testObjectStore.get Client, 1
		@testObjectStore.get Client, "1"
		begin
			@testObjectStore.get Client, "abc"
			fail "should throw exception for non-numeric index"
		rescue
			# ok
		end
	end

	def test_db_bridge
		assert_equal( @mockDbBridge, @testObjectStore.db_bridge )
	end
	
	def test_deep_linking
		client1 = Client.uncommitted_mock
		@mockDbBridge.commit client1
		client1Proxy = DomainObjectProxy.new(Client, 1)
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2',
				'referringClient' => client1Proxy })
		@mockDbBridge.commit client2
		client2Prime = @testObjectStore.client 2
		assert_equal Client, client2Prime.referringClient.domain_class
	end

	def test_defers_loading
		@testObjectStore.all Invoice
		assert_equal( 0, @mockDbBridge.queries( Client ).size )
		assert_equal( 1, @mockDbBridge.queries( Invoice ).size )
	end

	def test_delete_clears_cached_value
		client = Client.new({ 'pk_id' => 100, 'name' => 'client 100' })
		@testObjectStore.commit client
		assert_equal 1, @testObjectStore.all(Client).size
		client.delete = true
		@testObjectStore.commit client
		assert_equal 0, @testObjectStore.all(Client).size
	end

	def test_diff_pk
		diff = DiffSqlPrimaryKey.new( 'pk_id' => 1, 'text' => 'sample text' )
		@testObjectStore.commit diff
		diff_prime = @testObjectStore.diff_sql_primary_keys( 1, 'pk_id' ).first
		assert_equal( 'sample text', diff_prime.text )
	end

	def test_dispatches_inferred_query_to_collector
		set_test_client
		clients = @testObjectStore.clients { |client|
			client.name.equals( @client.name )
		}
	end
	
  def test_dumpable
		newOs = Marshal.load(Marshal.dump(@testObjectStore))
    assert_equal MockObjectStore, newOs.class
  end

	def test_dynamic_method_name_dispatching_raises_NoMethodError
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

	def test_dynamic_method_name_dispatches_to_collector_map_object_function
		option = Option.uncommitted_mock
		@testObjectStore.commit option
		ili = InventoryLineItem.uncommitted_mock
		@testObjectStore.commit ili
		ilio = InventoryLineItemOption.uncommitted_mock
		@testObjectStore.commit ilio
		assert_equal( ili, ilio.inventory_line_item )
		assert_equal ilio, @testObjectStore.inventory_line_item_option(
				ili, option)
	end

	def test_dynamic_method_names
		set_test_client
		assert_equal @client, @testObjectStore.client(1)
		invoice1 = Invoice.new( 'client' => nil ).commit
		invoice2 = Invoice.new( 'client' => @client ).commit
		begin
			@testObjectStore.invoices nil
			raise "Should raise ArgumentError"
		rescue ArgumentError
			expected = "ObjectStore#invoices needs a field name as its second " +
			           "argument if its first argument is nil"
			assert_equal( expected, $!.to_s )
		end
		coll = @testObjectStore.invoices( nil, 'client' )
		assert_equal( invoice1, coll.only )
		xml_sku = XmlSku.new( 'pk_id' => 1 ).commit
		user = User.committed_mock
		xml_sku2 = XmlSku2.new( 'xml_sku' => xml_sku, 'link1' => user ).commit
		coll2 = @testObjectStore.xml_sku2s( xml_sku )
		assert_equal( xml_sku2, coll2.only )
		assert_equal( xml_sku2, @testObjectStore.xml_sku2s( user ).only )
	end

	def test_dynamic_method_names_as_facade_for_collector
		set_test_client
		matchingClients = @testObjectStore.clients(@client.name, 'name')
		assert_equal 1, matchingClients.size
		assert_equal @client, matchingClients[0]
	end
	
	def test_flush
		client = Client.uncommitted_mock
		@mockDbBridge.commit client
		assert_equal client.name, @testObjectStore.get(Client, 1).name
		client.name = 'new client name'
		@mockDbBridge.commit client
		assert_equal client.name, @testObjectStore.get(Client, 1).name
		@testObjectStore.flush client
		assert_equal 'new client name', @testObjectStore.get(Client, 1).name
	end

	def test_flush_cache_after_new_object_commit
		assert_equal 0, @testObjectStore.all(Client).size
		client = Client.new({ })
		@testObjectStore.commit client
		assert_equal 1, @testObjectStore.all(Client).size
	end
	
	def test_get_map_object
		ili = InventoryLineItem.committed_mock
		option = Option.committed_mock
		iliOption = InventoryLineItemOption.committed_mock
		assert_equal 1, @testObjectStore.all(InventoryLineItemOption).size
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
	
	def test_get_with_a_non_linking_field	
		client = Client.uncommitted_mock
		@testObjectStore.commit client
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2' })
		@testObjectStore.commit client2
		assert_equal 2, @testObjectStore.clients('client 2', 'name')[0].pk_id
	end

	def test_handles_links_through_proxies
		invoice = Invoice.committed_mock
		origClient = @testObjectStore.get(Client, 1)
		assert_equal Client, origClient.class
		clientProxy = invoice.client
		assert_equal DomainObjectProxy, clientProxy.class
		matches = @testObjectStore.invoices(clientProxy)
		assert_equal 1, matches.size
	end

	def test_invoices
		client = Client.uncommitted_mock
		client.commit
		inv1 = Invoice.new(
			'client' => client, 'date' => Date.today, 'rate' => 30, 'hours' => 40
		)
		@testObjectStore.commit inv1
		inv2 = Invoice.new(
			'client' => client, 'date' => Date.today - 7, 'rate' => 30, 'hours' => 40
		)
		@testObjectStore.commit inv2
		coll = @testObjectStore.invoices(client)
		assert_equal 2, coll.size
	end

	def test_max
		set_test_client
		assert_equal 1, @testObjectStore.max(Client)
		Invoice.committed_mock
		assert_equal( 70, @testObjectStore.max( Invoice, 'rate' ) )
		xml_sku = XmlSku.new( 'pk_id' => 25 )
		xml_sku.commit
		assert_equal( 25, @testObjectStore.max( XmlSku ) )
	end

	def test_method_missing
		begin
			@testObjectStore.get_foo_bar
			raise "Should raise NoMethodError"
		rescue NoMethodError
			# okay
		end
	end

	def test_query
		set_test_client
		condition = Query::Equals.new 'name', 'clientName1', Client
		query = Query.new Client, condition
		assert_equal @client, @testObjectStore.query(condition)[0]
		assert_equal(
			1, @mockDbBridge.queries.select { |q| q.to_sql == query.to_sql }.size
		)
		assert_equal( 1, @mockDbBridge.query_count( query.to_sql ) )
		assert_equal @client, @testObjectStore.query(query)[0]
		assert_equal( 1, @mockDbBridge.query_count( query.to_sql ) )
		query2 = Query.new( Client, Query::Equals.new( 'name', 'foobar', Client ) )
		assert_equal( 0, @testObjectStore.query( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count( query2.to_sql ) )
		assert_equal( 0, @testObjectStore.query( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count( query2.to_sql ) )
		query2_prime = Query.new(
			Client, Query::Equals.new( 'name', 'foobar', Client )
		)
		assert_equal( 0, @testObjectStore.query( query2_prime ).size )
		assert_equal( 1, @mockDbBridge.query_count( query2_prime.to_sql ) )
	end

	def test_query_field_comparison
		inv1 = Invoice.new( 'date' => Date.today, 'paid' => Date.today + 30 )
		inv1.commit
		inv2 = Invoice.new( 'date' => Date.today, 'paid' => Date.today )
		inv2.commit
		matches = @testObjectStore.invoices { |inv|
			inv.date.equals( inv.paid )
		}
		assert_equal( 1, matches.size )
	end

	def test_query_inference
		1.upto( 3 ) do |i|
			Client.new( 'pk_id' => i, 'name' => "client #{ i }" ).commit
		end
		coll1 = @testObjectStore.clients { |client|
			client.name.equals( 'client 1' )
		}
		assert_equal( 1, coll1.size )
		assert_equal( 1, coll1[0].pk_id )
		coll2 = @testObjectStore.clients { |client|
			client.name.like( /^clie/ )
		}
		assert_equal( 3, coll2.size )
		coll3 = @testObjectStore.clients { |client|
			client.name.like( /^clie/ ).not
		}
		assert_equal( 0, coll3.size )
		assert_raise( ArgumentError ) do
			@testObjectStore.clients( 'client 1', 'name' ) { |client|
				client.name.equals( 'client 1' ).not
			}
		end
		coll4 = @testObjectStore.clients
		assert_equal( 3, coll4.size )
	end
	
	def test_raises_error_with_querying_with_uncommitted_dobj
		uncommitted = Client.new( {} )
		assert_raise( ArgumentError ) {
			@testObjectStore.invoices( uncommitted )
		}
	end

	def test_raises_exception_if_cant_find_object
		begin
			@testObjectStore.get Client, 1
			fail "should throw exception for unfindable object"
		rescue DomainObjectNotFoundError
			# ok
		end
	end
	
	def test_respond_to?
		[ :client, :clients ].each { |meth_id|
			assert( @testObjectStore.respond_to?( meth_id ), meth_id )
		}
		[ :get_foo_bar, :foo_bar ].each { |meth_id|
			assert( !@testObjectStore.respond_to?( meth_id ) )
		}
	end
	
	def test_self_linking
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
		client1Prime = @testObjectStore.client 1
		assert_equal 2, client1Prime.referringClient.pk_id
		assert_equal 100, client1Prime.referringClient.standard_rate
	end

	def test_update_flushes_cache
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

	class TestCache < LafcadioTestCase
		def setup
			super
			@cache = @mockObjectStore.cache
		end
	
		def all( domain_class )
			q = Query.new domain_class
			@cache.get_by_query q
		end
		
		def test_assigns_pk_id_on_new_commit
			client = Client.new({ 'name' => 'client name' })
			assert_nil client.pk_id
			@cache.commit client
			assert_not_nil client.pk_id
		end
	
		def test_caching_accounts_for_limits_and_sort_by
			@cache.commit( User.new( 'pk_id' => 1, 'firstNames' => 'aza' ) )
			@cache.commit( User.new( 'pk_id' => 2, 'firstNames' => 'bzb' ) )
			@cache.commit( User.new( 'pk_id' => 3, 'firstNames' => 'czc' ) )
			q = Query.infer( User ) { |tr| tr.firstNames.like( /z/ ) }
			assert_equal( 3, @cache.get_by_query( q ).size )
			q = Query.infer( User ) { |tr| tr.firstNames.like( /z/ ) }
			q.order_by = 'firstNames'
			q.order_by_order = Query::DESC
			coll = @cache.get_by_query q
			assert_equal( 3, coll.size )
			assert_equal( 'aza', coll.last.firstNames )
			q.order_by = nil
			q.limit = 0..0
			assert_equal( 1, @cache.get_by_query( q ).size )
		end

		def test_clones
			user = User.uncommitted_mock
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
			assert_equal( 0, @mockObjectStore.xml_skus.size )
		end
	
		def test_delete_sets_domain_object_fields_to_nil
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
	
		def test_flush
			user = User.uncommitted_mock
			user.commit
			assert_equal( 1, all( User ).size )
			user.delete = true
			user.commit
			assert_equal( 0, all( User ).size )
		end
	
		def test_last_commit_type
			client = Client.new({ 'name' => 'client name' })
			@cache.commit client
			assert_equal( :insert, client.last_commit_type )
			client2 = Client.new({ 'pk_id' => 25, 'name' => 'client 25' })
			@cache.commit client2
			assert_equal( :update, client2.last_commit_type )
			client2.delete = true
			@cache.commit client2
			assert_equal( :delete, client2.last_commit_type )
		end
	end

	class TestCommitSqlStatementsAndBinds < LafcadioTestCase
		def test_commit_sql_with_apostrophe
			client = Client.new( { "name" => "T'est name" } )
			assert_equal("T'est name", client.name)
			sql = ObjectStore::CommitSqlStatementsAndBinds.new(client)[0][0]
			assert_equal("T'est name", client.name)
			assert_not_nil sql.index("'T''est name'"), sql
		end
	
		def test_commit_sql_with_invoice
			invoice = Invoice.new(
				"client" => Client.uncommitted_mock, "rate" => 70,
				"date" => Date.new(2001, 4, 5), "hours" => 36.5, "pk_id" => 1
			)
			update_sql = ObjectStore::CommitSqlStatementsAndBinds.new(invoice)[0]
			assert_not_nil(update_sql =~ /update invoices/, update_sql)
			assert_not_nil(update_sql =~ /pk_id=1/, update_sql)
			invoice.delete = true
			deleteSQL = ObjectStore::CommitSqlStatementsAndBinds.new(invoice)[0]
			assert_not_nil(deleteSQL =~ /delete from invoices where pk_id=1/)
		end
	
		def test_field_names_for_sql
			sqlMaker = ObjectStore::CommitSqlStatementsAndBinds.new Invoice.uncommitted_mock
			assert_equal( 6, sqlMaker.get_name_value_pairs( Invoice ).size )
		end
		
		def test_inheritance_commit
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
	
		def test_insert_update_and_delete
			values = { "name" => "ClientName1" }
			client1a = Client.new values
			ObjectStore::CommitSqlStatementsAndBinds.new(client1a)[0]
			values["pk_id"] = 1
			client1b = Client.new values
			updateSql = ObjectStore::CommitSqlStatementsAndBinds.new(client1b)[0][0]
			assert_match( /update/, updateSql )
			assert_match( /pk_id/, updateSql )
			client1b.delete = true
			delete_sql = ObjectStore::CommitSqlStatementsAndBinds.new(client1b)[0][0]
			assert_match( /delete/, delete_sql )
			assert_match( /pk_id/, delete_sql )
			binds = ObjectStore::CommitSqlStatementsAndBinds.new(client1b)[0][1]
			assert_equal( 0, binds.size )
		end

		def test_sets_nulls
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

	class TestDbBridge < Test::Unit::TestCase
		include Lafcadio
	
		def setup
			LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
			ObjectStore::DbConnection.connection_class = MockDbi
			MockDbi.reset
			@dbb = ObjectStore::DbBridge.new
			@mockDbh = MockDbi.mock_dbh
			@client = Client.new( {"pk_id" => 1, "name" => "clientName1"} )
		end
	
		def teardown
			@dbb = nil
			ObjectStore::DbConnection.flush
			ObjectStore::DbConnection.db_name = nil
		end
	
		def test_all
			query = Query.new Domain::LineItem
			coll = @dbb.select_dobjs query
			assert_equal Array, coll.class
		end
	
		def test_commits_delete
			@client.delete = true
			@dbb.commit(@client)
			assert_equal(
				"delete from clients where pk_id=1", @mockDbh.sql_statements.last
			)
		end
	
		def test_commits_edit
			@dbb.commit(@client)
			sql = @mockDbh.sql_statements.last
			assert(sql.index("update clients set name='clientName1'") != nil, sql)
		end
	
		def test_commits_for_inherited_objects
			ic = InternalClient.new({ 'pk_id' => 1, 'name' => 'client name',
					'billingType' => 'trade' })
			@dbb.commit ic
			assert_equal 2, @mockDbh.sql_statements.size
			sql1 = @mockDbh.sql_statements[0]
			assert_not_nil sql1 =~ /update clients set/, sql1
			sql2 = @mockDbh.sql_statements[1]
			assert_match( /update internal_clients set/, sql2 )
		end
	
		def test_group_query
			query = Query::Max.new( Client )
			assert_equal( 1, @dbb.group_query( query ).only[:max] )
			invoice = Invoice.committed_mock
			query2 = Query::Max.new( Invoice, 'date' )
			assert_equal( invoice.date, @dbb.group_query( query2 ).only[:max].to_date )
			query3 = Query::Max.new( XmlSku )
			assert_equal( 5, @dbb.group_query( query3 ).only[:max] )
			query4 = Query::Max.new( Attribute )
			assert_nil( @dbb.group_query( query4 ).only[:max] )
		end
	
		def test_last_pk_id_inserted
			client = Client.new( { "name" => "clientName1" } )
			@dbb.commit client
			assert_equal 12, @dbb.last_pk_id_inserted
			dbb2 = ObjectStore::DbBridge.new
			assert_equal 12, dbb2.last_pk_id_inserted
		end
		
		def test_logs_sql
			logFilePath = '../test/testOutput/sql'
			@dbb.select_all 'select * from users'
			if FileTest.exist?( logFilePath )
				fail if Time.now - File.ctime( logFilePath ) < 5
			end
			LafcadioConfig.set_filename(
				'../test/testData/config_with_sql_logging.dat'
			)
			@dbb.select_all 'select * from clients'
			fail if Time.now - File.ctime( logFilePath ) > 5
		end
		
		def test_logs_sql_to_different_file_name
			LafcadioConfig.set_filename( '../test/testData/config_with_log_path.dat' )
			logFilePath = '../test/testOutput/another.sql'
			@dbb.select_all 'select * from users'
			fail if Time.now - File.ctime( logFilePath ) > 5
		end
		
		def test_passes_sql_value_converter_to_domain_class_init
			query = Query.new( XmlSku )
			xml_sku = @dbb.select_dobjs( query ).only
			assert_equal( 'foobar', xml_sku.text1 )
			assert_equal( 'foobar', xml_sku.text1 )
			assert_nil( xml_sku.date1 )
			assert_nil( xml_sku.date1 )
			assert_equal( DomainObjectProxy, xml_sku.link1.class )
			assert_equal( 1, xml_sku.link1.pk_id )
		end
	end

	class TestDbConnection < Test::Unit::TestCase
		include Lafcadio
	
		def setup
			LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
			ObjectStore::DbConnection.connection_class = MockDbi
			MockDbi.reset
		end
	
		def test_connection_pooling
			ObjectStore::DbConnection.connection_class = MockDbi
			100.times { ObjectStore::DbConnection.get_db_connection }
			ObjectStore::DbConnection.flush
			ObjectStore::DbConnection.connection_class = DBI
		end
	
		def test_db_name
			ObjectStore::DbConnection.connection_class = MockDbi
			ObjectStore::DbConnection.flush
			MockDbi.flush_instance_count
			ObjectStore.db_name = 'some_other_db'
			db = ObjectStore::DbBridge.new
			assert_equal 'some_other_db', MockDbi.db_name
			ObjectStore::DbConnection.connection_class = DBI
		end
		
		def test_disconnect
			ObjectStore::DbConnection.get_db_connection.disconnect
			@mockDbh = MockDbi.mock_dbh
			assert !@mockDbh.connected?
		end
	end

	class TestSqlToRubyValues < LafcadioTestCase
		def test_converts_pk_id
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
	
		def test_execute
			row_hash = { "id" => "1", "name" => "clientName1",
			"standard_rate" => "70" }
			converter = ObjectStore::SqlToRubyValues.new(Client, row_hash)
			assert_equal("clientName1", converter["name"])
			assert_equal(70, converter["standard_rate"])
		end
	
		def test_inheritance_construction
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
	
		def test_turns_link_ids_into_proxies
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
end

require '../test/mock/domain'
require '../test/mock/domain/Option'
require 'lafcadio/test'
require 'lafcadio/mock'

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
		assert_equal Client, client2Prime.referringClient.object_type
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

	def testDynamicMethodNameDispatchesToCollectorMapObjectFunction
		option = TestOption.getTestOption
		@testObjectStore.commit option
		ili = TestInventoryLineItem.getTestInventoryLineItem
		@testObjectStore.commit ili
		ilio = TestInventoryLineItemOption.getTestInventoryLineItemOption
		@testObjectStore.commit ilio
		assert_equal ilio, @testObjectStore.get_inventory_line_item_option(
				ili, option)
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
	
	def testGetDbBridge
		assert_equal( @mockDbBridge, @testObjectStore.get_db_bridge )
	end
	
	def testGetInvoices
		client = Client.getTestClient
		client.commit
		inv1 = Invoice.new({ 'invoiceNum' => 1, 'client' => client,
				'date' => Date.today, 'rate' => 30, 'hours' => 40 })
		
				@testObjectStore.commit inv1
		inv2 = Invoice.new({ 'invoiceNum' => 2, 'client' => client,
				'date' => Date.today - 7, 'rate' => 30, 'hours' => 40 })
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
		assert_equal( Option, option_prime.object_type )
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
		coll2 = @testObjectStore.get_objects(Client, [ "1", "2" ])
		assert_equal 2, coll.size
	end

	def testGetSubset
		setTestClient
		condition = Query::Equals.new 'name', 'clientName1', Client
		assert_equal @client, @testObjectStore.get_subset(condition)[0]
		query = Query.new Client, condition
		assert_equal @client, @testObjectStore.get_subset(query)[0]
		query2 = Query.new( Client, Query::Equals.new( 'name', 'foobar', Client ) )
		assert_equal( 0, @testObjectStore.get_subset( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count[query2])
		assert_equal( 0, @testObjectStore.get_subset( query2 ).size )
		assert_equal( 1, @mockDbBridge.query_count[query])
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

	def testGetWithaNonLinkingField	
		client = Client.getTestClient
		@testObjectStore.commit client
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2' })
		@testObjectStore.commit client2
		assert_equal 2, @testObjectStore.get_clients('client 2', 'name')[0].pk_id
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
		assert_raise( ArgumentError,
		                  "Can't query using an uncommitted domain object as a search term"
		                ) {
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

require '../test/mock/domain/Client'
require '../test/mock/domain/InventoryLineItem'
require '../test/mock/domain/InventoryLineItemOption'
require '../test/mock/domain/Option'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/mock/MockDbBridge'

class TestObjectStore < LafcadioTestCase
	def setup
		super
		context = Context.instance
		context.flush
		@mockDbBridge = MockDbBridge.new
		@testObjectStore = ObjectStore.new context, @mockDbBridge
		context.setObjectStore @testObjectStore
	end
	
	def setTestClient
		@client = Client.getTestClient
		@mockDbBridge.addObject @client
	end

	def testDeepLinking
		client1 = Client.getTestClient
		@mockDbBridge.addObject client1
		client1Proxy = DomainObjectProxy.new(Client, 1)
		client2 = Client.new({ 'objId' => 2, 'name' => 'client 2',
				'referringClient' => client1Proxy })
		@mockDbBridge.addObject client2
		client2Prime = @testObjectStore.getClient 2
		assert_equal Client, client2Prime.referringClient.objectType
	end

	def testDefersLoading
		@testObjectStore.getAll Invoice
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		assert_equal 1, @mockDbBridge.retrievalsByType[Invoice]
	end

	def testDeleteClearsCachedValue
		client = Client.new({ 'objId' => 100, 'name' => 'client 100' })
		@testObjectStore.commit client
		assert_equal 1, @testObjectStore.getAll(Client).size
		client.delete = true
		@testObjectStore.commit client
		assert_equal 0, @testObjectStore.getAll(Client).size
	end

	def test_dispatches_inferred_query_to_collector
		setTestClient
		clients = @testObjectStore.getClients { |client|
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
		assert_equal ilio, @testObjectStore.getInventoryLineItemOption(
				ili, option)
	end

	def testDynamicMethodNames
		setTestClient
		assert_equal @client, @testObjectStore.getClient(1)
		@testObjectStore.flush( @client )
	end

	def testDynamicMethodNamesAsFacadeForCollector
		setTestClient
		matchingClients = @testObjectStore.getClients(@client.name, 'name')
		assert_equal 1, matchingClients.size
		assert_equal @client, matchingClients[0]
	end
	
	def testDynamicMethodNameDispatchingRaisesNoMethodError
		begin
			@testObjectStore.notAMethod
			raise "Should raise NoMethodError"
		rescue NoMethodError
			assert_match( /undefined method 'notAMethod'/, $!.to_s )
		end
		begin
			@testObjectStore.getFooBar
			raise "Should raise NoMethodError"
		rescue NoMethodError
			assert_match( /undefined method 'getFooBar'/, $!.to_s )
			# ok
		end
	end

	def testFlushCacheAfterNewObjectCommit
		assert_equal 0, @testObjectStore.getAll(Client).size
		client = Client.new({ })
		@testObjectStore.commit client
		assert_equal 1, @testObjectStore.getAll(Client).size
	end
	
	def testGetDbBridge
		assert_equal( @mockDbBridge, @testObjectStore.getDbBridge )
	end

	def testGetSubset
		setTestClient
		condition = Query::Equals.new 'name', 'clientName1', Client
		assert_equal @client, @testObjectStore.getSubset(condition)[0]
		query = Query.new Client, condition
		assert_equal @client, @testObjectStore.getSubset(query)[0]
	end

	def testMax
		setTestClient
		assert_equal 1, @testObjectStore.getMax(Client)
	end

	def testSelfLinking
		client1Proxy = DomainObjectProxy.new(Client, 1)
		client2Proxy = DomainObjectProxy.new(Client, 2)
		client1 = Client.new({ 'objId' => 1, 'name' => 'client 1',
														'standard_rate' => 50,
														'referringClient' => client2Proxy })
		@mockDbBridge.addObject client1
		client2 = Client.new({ 'objId' => 2, 'name' => 'client 2',
														'standard_rate' => 100,
														'referringClient' => client1Proxy })
		@mockDbBridge.addObject client2
		client1Prime = @testObjectStore.getClient 1
		assert_equal 2, client1Prime.referringClient.objId
		assert_equal 100, client1Prime.referringClient.standard_rate
	end

	def testUpdateFlushesCache
		client = Client.new({ 'objId' => 100, 'name' => 'client 100' })
		@testObjectStore.commit client
		assert_equal 'client 100', @testObjectStore.get(Client, 100).name
		clientPrime = Client.new({ 'objId' => 100, 'name' => 'client 100.1' })
		@testObjectStore.commit clientPrime
		assert_equal 'client 100.1', @testObjectStore.get(Client, 100).name
		clientPrime.name = 'client 100.2'
		@testObjectStore.commit clientPrime
		assert_equal 'client 100.2', @testObjectStore.get(Client, 100).name		
	end
	
	def test_getMapped
		ili = TestInventoryLineItem.storedTestInventoryLineItem
		option = TestOption.storedTestOption
		iliOption = TestInventoryLineItemOption.storedTestInventoryLineItemOption
		collection = @testObjectStore.getMapped( ili, 'Option' )
		assert_equal( 1, collection.size )
		option_prime = collection.first
		assert_equal( Option, option_prime.objectType )
		assert_equal( option, option_prime )
	end

	def testGetObjects
		@testObjectStore.commit Client.new( { "objId" => 1, "name" => "clientName1" } )
		@testObjectStore.commit Client.new( { "objId" => 2, "name" => "clientName2" } )
		coll = @testObjectStore.getObjects(Client, [ 1, 2 ])
		assert_equal 2, coll.size
		foundOne = false
		foundTwo = false
		coll.each { |obj|
			foundOne = true if obj.objId == 1
			foundTwo = true if obj.objId == 2
		}
		assert foundOne
		assert foundTwo
		coll2 = @testObjectStore.getObjects(Client, [ "1", "2" ])
		assert_equal 2, coll.size
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
		coll = @testObjectStore.getInvoices(client)
		assert_equal 2, coll.size
	end

	def testGetWithaNonLinkingField	
		client = Client.getTestClient
		@testObjectStore.commit client
		client2 = Client.new({ 'objId' => 2, 'name' => 'client 2' })
		@testObjectStore.commit client2
		assert_equal 2, @testObjectStore.getClients('client 2', 'name')[0].objId
	end

	def testHandlesLinksThroughProxies
		invoice = Invoice.storedTestInvoice
		origClient = @testObjectStore.get(Client, 1)
		assert_equal Client, origClient.class
		clientProxy = invoice.client
		assert_equal DomainObjectProxy, clientProxy.class
		matches = @testObjectStore.getInvoices(clientProxy)
		assert_equal 1, matches.size
	end

	def testGetMapObject
		ili = TestInventoryLineItem.storedTestInventoryLineItem
		option = TestOption.storedTestOption
		iliOption = TestInventoryLineItemOption.storedTestInventoryLineItemOption
		assert_equal 1, @testObjectStore.getAll(InventoryLineItemOption).size
		assert_equal iliOption, @testObjectStore.getMapObject(InventoryLineItemOption,
				ili, option)
		begin
			@testObjectStore.getMapObject InventoryLineItemOption, ili, nil
			fail 'Should throw an error'
		rescue ArgumentError
			errorStr = $!.to_s
			assert_equal "ObjectStore#getMapObject needs two non-nil keys", errorStr
		end 
	end
	
	def test_query_inference
		client1 = Client.new( 'objId' => 1, 'name' => 'client 1' )
		client1.commit
		client2 = Client.new( 'objId' => 2, 'name' => 'client 2' )
		client2.commit
		client3 = Client.new( 'objId' => 3, 'name' => 'client 3' )
		client3.commit
		coll1 = @testObjectStore.getClients { |client| client.name.equals( 'client 1' ) }
		assert_equal( 1, coll1.size )
		assert_equal( 1, coll1[0].objId )
		coll2 = @testObjectStore.getClients { |client| client.name.like( /^clie/ ) }
		assert_equal( 3, coll2.size )
		coll3 = @testObjectStore.getClients { |client| client.name.like( /^clie/ ).not }
		assert_equal( 0, coll3.size )
		begin
			@testObjectStore.getClients( 'client 1', 'name' ) { |client|
				client.name.equals( 'client 1' ).not
			}
			raise "Should raise ArgumentError"
		rescue ArgumentError
			# okay
		end
	end
	
	def test_method_missing
		begin
			@testObjectStore.getFooBar
			raise "Should raise NoMethodError"
		rescue NoMethodError
			# okay
		end
	end

	def testConvertsFixnums
		@mockDbBridge.addObject Client.getTestClient
		@testObjectStore.get Client, 1
		@testObjectStore.get Client, "1"
		begin
			@testObjectStore.get Client, "abc"
			fail "should throw exception for non-numeric index"
		rescue
			# ok
		end
	end

	def testCaching
		@testObjectStore.getAll Invoice
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		assert_equal 1, @mockDbBridge.retrievalsByType[Invoice]
		@testObjectStore.getAll Invoice
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		assert_equal 1, @mockDbBridge.retrievalsByType[Invoice]
		@testObjectStore.getAll Client
		assert_equal 1, @mockDbBridge.retrievalsByType[Client]
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

	def testRaisesExceptionIfCantFindObject
		begin
			@testObjectStore.get Client, 1
			fail "should throw exception for unfindable object"
		rescue DomainObjectNotFoundError
			# ok
		end
	end
end

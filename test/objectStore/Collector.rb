require 'test/mock/domain/Option'
require 'test/mock/domain/InventoryLineItem'
require 'test/mock/domain/InventoryLineItemOption'
require 'test/mock/domain/Invoice'
require 'date'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/objectStore/Collector'
require 'test/mock/domain/Client'

class TestObjectCollector < LafcadioTestCase
	def setup
		super
		@collector = Collector.new @mockObjectStore
	end

	def testGetObjects
		@mockObjectStore.addObject Client.new( { "objId" => 1, "name" => "clientName1" } )
		@mockObjectStore.addObject Client.new( { "objId" => 2, "name" => "clientName2" } )
		coll = @collector.getObjects(Client, [ 1, 2 ])
		assert_equal 2, coll.size
		foundOne = false
		foundTwo = false
		coll.each { |obj|
			foundOne = true if obj.objId == 1
			foundTwo = true if obj.objId == 2
		}
		assert foundOne
		assert foundTwo
		coll2 = @collector.getObjects(Client, [ "1", "2" ])
		assert_equal 2, coll.size
	end

	def testGetInvoices
		client = Client.getTestClient
		@mockObjectStore.addObject client
		inv1 = Invoice.new({ 'invoiceNum' => 1, 'client' => client,
				'date' => Date.today, 'rate' => 30, 'hours' => 40 })
		@mockObjectStore.addObject inv1
		inv2 = Invoice.new({ 'invoiceNum' => 2, 'client' => client,
				'date' => Date.today - 7, 'rate' => 30, 'hours' => 40 })
		@mockObjectStore.addObject inv2
		coll = @collector.getInvoices(client)
		assert_equal 2, coll.size
	end

	def testGetWithaNonLinkingField	
		client = Client.getTestClient
		@mockObjectStore.addObject client
		client2 = Client.new({ 'objId' => 2, 'name' => 'client 2' })
		@mockObjectStore.addObject client2
		assert_equal 2, @collector.getClients('client 2', 'name')[0].objId
	end

	def testHandlesLinksThroughProxies
		invoice = Invoice.storedTestInvoice
		origClient = @mockObjectStore.get(Client, 1)
		assert_equal Client, origClient.class
		clientProxy = invoice.client
		assert_equal DomainObjectProxy, clientProxy.class
		matches = @collector.getInvoices(clientProxy)
		assert_equal 1, matches.size
	end

	def testGetMapObject
		ili = TestInventoryLineItem.storedTestInventoryLineItem
		option = TestOption.storedTestOption
		iliOption = TestInventoryLineItemOption.storedTestInventoryLineItemOption
		assert_equal 1, @mockObjectStore.getAll(InventoryLineItemOption).size
		assert_equal iliOption, @collector.getMapObject(InventoryLineItemOption,
				ili, option)
		begin
			@collector.getMapObject InventoryLineItemOption, ili, nil
			fail 'Should throw an error'
		rescue ArgumentError
			errorStr = $!.to_s
			assert_equal "Collector#getMapObject needs two non-nil keys", errorStr
		end 
	end
	
	def test_query_inference
		client1 = Client.new( 'objId' => 1, 'name' => 'client 1' )
		client1.commit
		client2 = Client.new( 'objId' => 2, 'name' => 'client 2' )
		client2.commit
		client3 = Client.new( 'objId' => 3, 'name' => 'client 3' )
		client3.commit
		coll1 = @collector.getClients { |client| client.name.equals( 'client 1' ) }
		assert_equal( 1, coll1.size )
		assert_equal( 1, coll1[0].objId )
		coll2 = @collector.getClients { |client| client.name.like( /^clie/ ) }
		assert_equal( 3, coll2.size )
		coll3 = @collector.getClients { |client| client.name.like( /^clie/ ).not }
		assert_equal( 0, coll3.size )
		begin
			@collector.getClients( 'client 1', 'name' ) { |client|
				client.name.equals( 'client 1' ).not
			}
			raise "Should raise ArgumentError"
		rescue ArgumentError
			# okay
		end
	end
end
require 'test/mock/domain/Client'
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

  def testDumpable
		newOs = Marshal.load (Marshal.dump @testObjectStore)
    assert_equal ObjectStore, newOs.type
  end

	def testDynamicMethodNames
		setTestClient
		assert_equal @client, @testObjectStore.getClient(1)
	end

	def testDynamicMethodNamesAsFacadeForCollector
		setTestClient
		matchingClients = @testObjectStore.getClients(@client.name, 'name')
		assert_equal 1, matchingClients.size
		assert_equal @client, matchingClients[0]
	end

	def testDeepLinking
		client1 = Client.getTestClient
		@mockDbBridge.addObject client1
		client1Proxy = DomainObjectProxy.new(Client, 1)
		client2 = Client.new ({ 'objId' => 2, 'name' => 'client 2',
				'referringClient' => client1Proxy })
		@mockDbBridge.addObject client2
		client2Prime = @testObjectStore.getClient 2
		assert_equal Client, client2Prime.referringClient.objectType
	end

	def testSelfLinking
		client1Proxy = DomainObjectProxy.new(Client, 1)
		client2Proxy = DomainObjectProxy.new(Client, 2)
		client1 = Client.new ({ 'objId' => 1, 'name' => 'client 1',
														'standard_rate' => 50,
														'referringClient' => client2Proxy })
		@mockDbBridge.addObject client1
		client2 = Client.new ({ 'objId' => 2, 'name' => 'client 2',
														'standard_rate' => 100,
														'referringClient' => client1Proxy })
		@mockDbBridge.addObject client2
		client1Prime = @testObjectStore.getClient 1
		assert_equal 2, client1Prime.referringClient.objId
		assert_equal 100, client1Prime.referringClient.standard_rate
	end

	def testDefersLoading
		@testObjectStore.getAll Invoice
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		assert_equal 1, @mockDbBridge.retrievalsByType[Invoice]
	end

	def testUpdateFlushesCache
		client = Client.new ({ 'objId' => 100, 'name' => 'client 100' })
		@testObjectStore.commit client
		assert_equal 'client 100', @testObjectStore.get(Client, 100).name
		clientPrime = Client.new ({ 'objId' => 100, 'name' => 'client 100.1' })
		@testObjectStore.commit clientPrime
		assert_equal 'client 100.1', @testObjectStore.get(Client, 100).name
	end

	def testDeleteClearsCachedValue
		client = Client.new ({ 'objId' => 100, 'name' => 'client 100' })
		@testObjectStore.commit client
		assert_equal 1, @testObjectStore.getAll(Client).size
		client.delete = true
		@testObjectStore.commit client
		assert_equal 0, @testObjectStore.getAll(Client).size
	end

	def testMax
		setTestClient
		assert_equal 1, @testObjectStore.getMax(Client)
	end

	def testGetSubset
		setTestClient
		condition = Query::Equals.new 'name', 'clientName1', Client
		assert_equal @client, @testObjectStore.getSubset(condition)[0]
		query = Query.new Client, condition
		assert_equal @client, @testObjectStore.getSubset(query)[0]
	end
end

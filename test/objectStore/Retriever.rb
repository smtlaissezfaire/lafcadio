require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/mock/MockDbBridge'
require '../test/mock/domain/Client'

class TestRetriever < LafcadioTestCase
	def setup
		super
		@mockDbBridge = MockDbBridge.new
		@retriever = ObjectStore::Retriever.new(@mockDbBridge)
	end

	def testConvertsFixnums
		@mockDbBridge.addObject Client.getTestClient
		@retriever.get Client, 1
		@retriever.get Client, "1"
		begin
			@retriever.get Client, "abc"
			fail "should throw exception for non-numeric index"
		rescue
			# ok
		end
	end

	def testCaching
		@retriever.getAll Invoice
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		assert_equal 1, @mockDbBridge.retrievalsByType[Invoice]
		@retriever.getAll Invoice
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		assert_equal 1, @mockDbBridge.retrievalsByType[Invoice]
		@retriever.getAll Client
		assert_equal 1, @mockDbBridge.retrievalsByType[Client]
	end

	def testFlush
		client = Client.getTestClient
		@mockDbBridge.commit client
		assert_equal client.name, @retriever.get(Client, 1).name
		client.name = 'new client name'
		@mockDbBridge.commit client
		assert_equal client.name, @retriever.get(Client, 1).name
		@retriever.flush client
		assert_equal 'new client name', @retriever.get(Client, 1).name
	end

	def testClear
		client = Client.getTestClient
		@mockDbBridge.commit client
		assert_equal 1, @retriever.getAll(Client).size
		@retriever.clear client
		assert_equal 0, @retriever.getAll(Client).size
	end

	def testGetAllAndGetUseSameCache
		client = Client.getTestClient
		@mockDbBridge.commit client
		assert_not_nil @retriever.get(Client, 1)
		assert_equal 1, @retriever.getAll(Client).size
		@retriever.flush client
		assert_equal 0, @retriever.getAll(Client).size
	end

	def testRaisesExceptionIfCantFindObject
		begin
			@retriever.get Client, 1
			fail "should throw exception for unfindable object"
		rescue DomainObjectNotFoundError
			# ok
		end
	end
end

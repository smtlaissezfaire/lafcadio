require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'
require 'test/mock/domain/SKU'

class TestMockDBBridge < LafcadioTestCase
  def setup
  	super
		@mockDbBridge = MockDbBridge.new
    @client = Client.new( {"objId" => 1, "name" => "clientName1"} )
  end

  def testDumpable
		assert_equal MockDbBridge, Marshal.load(Marshal.dump(@mockDbBridge)).class
  end

  def testLastObjIdInserted
		assert_equal nil, @mockDbBridge.lastObjIdInserted
    client = Client.new( { "name" => "clientName1" } )
    @mockDbBridge.commit client
    assert_equal 1, @mockDbBridge.lastObjIdInserted
    assert_equal 1, client.objId
		client2 = Client.new({ 'objId' => 2 })
		@mockDbBridge.commit client2
		assert_equal 2, client2.objId
		client3 = Client.new({ })
		@mockDbBridge.commit client3
		assert_equal 3, @mockDbBridge.lastObjIdInserted
		assert_equal 3, client3.objId
  end

	def testGetCollectionByQuery
		@mockDbBridge.commit @client
		client2 = Client.new({ 'objId' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		query = Query.new Client, 2
		coll = @mockDbBridge.getCollectionByQuery(query)
		assert_equal 1, coll.size
		assert_equal client2, coll[0]
	end

	def getAll(objectType)
		query = Query.new objectType
		@mockDbBridge.getCollectionByQuery query
	end

	def testGetAll
		@mockDbBridge.commit @client
		assert_equal @client, getAll(Client)[0]
	end

  def test_returnsCollection
    assert_equal(Array, getAll(Client).class)
  end

	def testRetrievalsByType
		assert_equal 0, @mockDbBridge.retrievalsByType[Client]
		getAll Client
		assert_equal 1, @mockDbBridge.retrievalsByType[Client]
		getAll Client
		assert_equal 2, @mockDbBridge.retrievalsByType[Client]
	end

	def get(objectType, objId)
		query = Query.new objectType, objId
		@mockDbBridge.getCollectionByQuery(query)[0]
	end

	def testUpdate
		client100 = Client.new( { 'objId' => 100, 'name' => 'client 100' } )
		@mockDbBridge.commit client100
		assert_equal 'client 100', get(Client, 100).name
		client100Prime = Client.new( { 'objId' => 100, 'name' => 'client 100.1' })
		@mockDbBridge.commit client100Prime
		assert_equal 'client 100.1', get(Client, 100).name
	end

	def testDelete
		@mockDbBridge.commit @client
		client2 = Client.new({ 'objId' => 2, 'name' => 'client2' })
		@mockDbBridge.commit client2
		assert_equal 2, getAll(Client).size
		@client.delete = true
		@mockDbBridge.commit @client
		assert_equal 1, getAll(Client).size
		query = Query.new Client, 1
		clientPrime = @mockDbBridge.getCollectionByQuery(query)[0]
		assert_nil clientPrime
	end
end
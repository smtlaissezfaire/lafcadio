require 'date'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/mock/MockDbBridge'
require '../test/mock/domain/Client'
require 'lafcadio/objectStore/Committer'

class TestDbObjectCommitter < LafcadioTestCase
	def setup
		super
		context = Context.instance
		context.flush
		@mockDBBridge = MockDbBridge.new
		@testObjectStore = ObjectStore.new context, @mockDBBridge
    context.setObjectStore @testObjectStore
	end
	
	def getFromDbBridge(objectType, objId)
		query = Query.new objectType, objId
		@mockDBBridge.getCollectionByQuery(query)[0]
	end

  def testDeleteSetsLinkFieldsToNil
		client = Client.new({ 'objId' => 1, 'name' => 'client name' })
		invoice = Invoice.new({ 'objId' => 1,
				'client' => DomainObjectProxy.new(client), 'date' => Date.new(2000, 1, 17),
				'rate' => 45, 'hours' => 20 })
    @mockDBBridge.addObject client
    @mockDBBridge.addObject invoice
    client.delete = true
    committer = Committer.new(client, @mockDBBridge)
    committer.execute
		assert_nil getFromDbBridge(Client, 1)
		assert_not_nil getFromDbBridge(Invoice, 1)
		assert_nil @testObjectStore.get(Invoice, 1).client
  end

	def testAssignsObjIdOnNewCommit
		client = Client.new({ 'name' => 'client name' })
		assert_nil client.objId
    committer = Committer.new(client, @mockDBBridge)
    committer.execute
		assert_not_nil client.objId
	end

	def testCommitType
		client = Client.new({ 'name' => 'client name' })
    committer = Committer.new(client, @mockDBBridge)
    committer.execute
		assert_equal Committer::INSERT, committer.commitType
		client2 = Client.new({ 'objId' => 25, 'name' => 'client 25' })
		committer2 = Committer.new(client2, @mockDBBridge)
		committer2.execute
		assert_equal Committer::UPDATE, committer2.commitType
		client2.delete = true
		committer3 = Committer.new(client2, @mockDBBridge)
		committer3.execute
		assert_equal Committer::DELETE, committer3.commitType
	end
end

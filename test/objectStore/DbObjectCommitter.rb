require 'date'
require 'lafcadio/test'
require 'lafcadio/mock'
require '../test/mock/domain/Client'
require 'lafcadio/objectStore'

class TestDbObjectCommitter < LafcadioTestCase
	def setup
		super
		context = Context.instance
		context.flush
		@mockDBBridge = MockDbBridge.new
		@testObjectStore = ObjectStore.new( @mockDBBridge )
    context.set_object_store @testObjectStore
	end
	
	def getFromDbBridge(object_type, pk_id)
		query = Query.new object_type, pk_id
		@mockDBBridge.get_collection_by_query(query)[0]
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
		assert_equal( 0, @testObjectStore.getXmlSkus.size )
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
end

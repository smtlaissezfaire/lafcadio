require 'test/mock/domain/Invoice'
require 'lafcadio/objectField/SubsetLinkField'
require 'lafcadio/domain/DomainObject'
require 'lafcadio/objectField/TextField'
require 'lafcadio/objectField/MoneyField'

class Client < Lafcadio::DomainObject
	include Lafcadio
	
  def Client.getTestClient
    Client.new( { "name" => "clientName1", 'objId' => 1 } )
  end

	def Client.storedTestClient
		client = Client.getTestClient
		Context.instance.getObjectStore.addObject client
		client
	end

  def testObjId
    client = Client.new( { "name" => "clientName1", "objId" => 1 } )
    assert_equal(1, client.objId)
  end

  def testEquality
    dbd = "clientName1"
    client1 = Client.new( { "name" => dbd, "objId" => 1 } )
    client2 = Client.new( { "name" => dbd, "objId" => 1 } )
    assert_equal(client1, client2)
  end
end

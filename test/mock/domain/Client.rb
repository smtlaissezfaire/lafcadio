require '../test/mock/domain/Invoice'
require 'lafcadio/objectField/SubsetLinkField'
require 'lafcadio/domain'
require 'lafcadio/objectField'

class Client < Lafcadio::DomainObject
	include Lafcadio
	
  def Client.getTestClient
    Client.new( { "name" => "clientName1", 'pkId' => 1 } )
  end

	def Client.storedTestClient
		client = Client.getTestClient
		Context.instance.getObjectStore.commit client
		client
	end

  def testPkId
    client = Client.new( { "name" => "clientName1", "pkId" => 1 } )
    assert_equal(1, client.pkId)
  end

  def testEquality
    dbd = "clientName1"
    client1 = Client.new( { "name" => dbd, "pkId" => 1 } )
    client2 = Client.new( { "name" => dbd, "pkId" => 1 } )
    assert_equal(client1, client2)
  end
end

require '../test/mock/domain/Invoice'
require 'lafcadio/domain'
require 'lafcadio/objectField'

class Client < Lafcadio::DomainObject
	include Lafcadio
	
  def Client.getTestClient
    Client.new( { "name" => "clientName1", 'pk_id' => 1 } )
  end

	def Client.storedTestClient
		client = Client.getTestClient
		Context.instance.get_object_store.commit client
		client
	end

  def testPkId
    client = Client.new( { "name" => "clientName1", "pk_id" => 1 } )
    assert_equal(1, client.pk_id)
  end

  def testEquality
    dbd = "clientName1"
    client1 = Client.new( { "name" => dbd, "pk_id" => 1 } )
    client2 = Client.new( { "name" => dbd, "pk_id" => 1 } )
    assert_equal(client1, client2)
  end
end

require 'test/mock/domain/Invoice'
require 'lafcadio/objectField/SubsetLinkField'
require 'lafcadio/domain/DomainObject'
require 'lafcadio/objectField/TextField'
require 'lafcadio/objectField/MoneyField'

class Client < DomainObject
  def Client.classFields
		fields = [ TextField.new(Client, "name") ]
    standardRateField = MoneyField.new(Client, "standard_rate",
				"Standard Rate")
    standardRateField.notNull = false
		fields << standardRateField
		fields <<(LinkField.new(self, Client, 'referringClient'))
		priorityInvoice = SubsetLinkField.new self, Invoice, 'client',
				'priorityInvoice'
		priorityInvoice.notNull = false
		fields << priorityInvoice
		fields
  end
  
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

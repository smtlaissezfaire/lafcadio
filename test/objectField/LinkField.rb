require 'lafcadio/objectStore'
require 'lafcadio/test'
require '../test/mock/domain/Client'
require '../test/mock/domain/InternalClient'
require 'lafcadio/objectField'
require '../test/mock/domain/Invoice'
require '../test/mock/domain/LineItem'

class TestLinkField < LafcadioTestCase
  def setup
		super
    @olf = LinkField.new(nil, Client)
		@mockObjectStore.addObject Client.new(
				{ "pkId" => 1, "name" => "clientName1" } )
		@mockObjectStore.addObject Client.new(
				{ "pkId" => 2, "name" => "clientName2" } )
    @fieldWithListener = LinkField.new(nil, Client, "client", "Client")
    rateField = MoneyField.new nil, "rate"
  end

  def testNames
    assert_equal("Client", @olf.englishName)
    assert_equal("client", @olf.name)
		caLinkField = LinkField.new nil, InternalClient
		assert_equal "internalClient", caLinkField.name
		liLinkField = LinkField.new nil, Domain::LineItem
		assert_equal "lineItem", liLinkField.name
  end

  def testValueForSQL
    client = Client.new( { "name" => "my name", "pkId" => 10 } )
    assert_equal(10, @olf.valueForSQL(client))
		badClient = Client.new({ 'name' => 'Bad client' })
		begin
			@olf.valueForSQL(badClient)
			fail 'needs to throw DBObjectInitError'
		rescue DomainObjectInitError
			# ok
		end
		assert_equal("null", @olf.valueForSQL(nil))
  end

	def testValueForSqlForProxies
		clientProxy = DomainObjectProxy.new(Client, 45)
		assert_equal 45, @olf.valueForSQL(clientProxy)
	end

  def testNameForSQL
    assert_equal("client", @olf.nameForSQL)
  end

  def testValueFromSQL
		client = Client.getTestClient
		@mockObjectStore.addObject client
		clientFromLinkField = @olf.valueFromSQL("1")
		assert_equal DomainObjectProxy, clientFromLinkField.class
		assert_equal client.name, clientFromLinkField.name
		assert_nil @olf.valueFromSQL(nil)
  end

	def testRespectsOtherSubsetLinks
		invoice = Invoice.storedTestInvoice
		client = Client.storedTestClient
		client.priorityInvoice = invoice
		@mockObjectStore.commit client
		client2 = client.clone
		client2.pkId = 2
		@mockObjectStore.commit client2
		linkField = Invoice.getClassField 'client'
		begin
			linkField.verify(client2, 1)
			fail 'should throw FieldValueError'
		rescue FieldValueError
			# ok
		end
	end
end

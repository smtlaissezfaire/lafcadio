require 'lafcadio/objectStore'
require 'lafcadio/test'
require '../test/mock/domain'
require 'lafcadio/objectField'

class TestLinkField < LafcadioTestCase
  def setup
		super
    @olf = LinkField.new(nil, Client)
		@mockObjectStore.commit Client.new(
				{ "pk_id" => 1, "name" => "clientName1" } )
		@mockObjectStore.commit Client.new(
				{ "pk_id" => 2, "name" => "clientName2" } )
    @fieldWithListener = LinkField.new(nil, Client, "client", "Client")
  end

  def testNames
    assert_equal("client", @olf.name)
		caLinkField = LinkField.new nil, InternalClient
		assert_equal "internalClient", caLinkField.name
		liLinkField = LinkField.new nil, Domain::LineItem
		assert_equal "lineItem", liLinkField.name
  end

  def testValueForSQL
    client = Client.new( { "name" => "my name", "pk_id" => 10 } )
    assert_equal(10, @olf.value_for_sql(client))
		badClient = Client.new({ 'name' => 'Bad client' })
		begin
			@olf.value_for_sql(badClient)
			fail 'needs to throw DBObjectInitError'
		rescue DomainObjectInitError
			# ok
		end
		assert_equal("null", @olf.value_for_sql(nil))
  end

	def testValueForSqlForProxies
		clientProxy = DomainObjectProxy.new(Client, 45)
		assert_equal 45, @olf.value_for_sql(clientProxy)
	end

  def testNameForSQL
    assert_equal("client", @olf.name_for_sql)
  end

  def testValueFromSQL
		client = Client.getTestClient
		@mockObjectStore.commit client
		clientFromLinkField = @olf.value_from_sql("1")
		assert_equal DomainObjectProxy, clientFromLinkField.class
		assert_equal client.name, clientFromLinkField.name
		assert_nil @olf.value_from_sql(nil)
  end

	def testRespectsOtherSubsetLinks
		invoice = Invoice.storedTestInvoice
		client = Client.storedTestClient
		client.priorityInvoice = invoice
		@mockObjectStore.commit client
		client2 = client.clone
		client2.pk_id = 2
		@mockObjectStore.commit client2
		linkField = Invoice.get_class_field 'client'
		begin
			linkField.verify(client2, 1)
			fail 'should throw FieldValueError'
		rescue FieldValueError
			# ok
		end
	end
end

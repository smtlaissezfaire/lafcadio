require 'lafcadio/objectField'
require 'lafcadio/domain'
require 'lafcadio/test'
require '../test/mock/domain/Option'

class Attribute < Lafcadio::DomainObject
	def Attribute.table_name
		"attributes"
	end

	def Attribute.additionalHeaderFieldNames
		[ "Options" ]
	end

	def Attribute.otherTypesToDisplay
		[ Option ]
	end

	def Attribute.addEditHomepage
		"admin/attributes.rhtml"
	end
end

class Client < Lafcadio::DomainObject
	include Lafcadio
	
  def Client.getTestClient
    Client.new( { "name" => "clientName1", 'pk_id' => 1 } )
  end

	def Client.storedTestClient
		client = Client.getTestClient
		ObjectStore.get_object_store.commit client
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

class InternalClient < Client; end

class NoXml < Lafcadio::DomainObject
	def NoXml.get_class_fields; super; end
	
	sql_primary_key_name 'no_xml_id'
end

class TestAttribute < LafcadioTestCase
	def TestAttribute.getTestAttribute
		Attribute.new( { "pk_id" => 1, "name" => "attribute name" })
	end

	def TestAttribute.storedTestAttribute
		att = getTestAttribute
		ObjectStore.get_object_store.commit att
		att
	end
end

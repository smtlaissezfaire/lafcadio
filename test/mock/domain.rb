require 'lafcadio/objectField'
require 'lafcadio/domain'
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

require 'lafcadio/test'

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

class NoXml < Lafcadio::DomainObject
	def NoXml.get_class_fields; super; end
end
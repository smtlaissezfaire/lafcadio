require 'lafcadio/objectField/TextField'
require 'lafcadio/domain/DomainObject'
require 'test/mock/domain/Option'

class Attribute < DomainObject
	def Attribute.tableName
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

require 'lafcadio/test/LafcadioTestCase'

class TestAttribute < LafcadioTestCase
	def TestAttribute.getTestAttribute
		Attribute.new( { "objId" => 1, "name" => "attribute name" })
	end

	def TestAttribute.storedTestAttribute
		att = getTestAttribute
		Context.instance.getObjectStore.addObject att
		att
	end
end

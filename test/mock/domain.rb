require 'lafcadio/objectField'
require 'lafcadio/domain'
require '../test/mock/domain/Option'

class Attribute < Lafcadio::DomainObject
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

require 'lafcadio/test'

class TestAttribute < LafcadioTestCase
	def TestAttribute.getTestAttribute
		Attribute.new( { "pkId" => 1, "name" => "attribute name" })
	end

	def TestAttribute.storedTestAttribute
		att = getTestAttribute
		Context.instance.getObjectStore.commit att
		att
	end
end

class NoXml < Lafcadio::DomainObject; def NoXml.getClassFields; []; end; end
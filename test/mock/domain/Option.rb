require 'lafcadio/domain/DomainObject'
require '../test/mock/domain'
require 'lafcadio/objectField/LinkField'

class Option < Lafcadio::DomainObject
	def addEditHomepage
		"admin/ae.rhtml?objectType=Attribute&objId=#{attribute.objId}"
	end
end

require 'lafcadio/test/LafcadioTestCase'

class TestOption < LafcadioTestCase
	def TestOption.getTestOption
		Option.new( { "attribute" => TestAttribute.getTestAttribute,
				"name" => "option name", "objId" => 1 } )
	end

	def TestOption.storedTestOption
		opt = getTestOption
		opt.attribute = TestAttribute.storedTestAttribute
		Context.instance.getObjectStore.addObject opt
		opt
	end
end
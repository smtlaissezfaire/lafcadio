require 'lafcadio/domain'
require '../test/mock/domain'
require 'lafcadio/objectField'

class Option < Lafcadio::DomainObject
	def addEditHomepage
		"admin/ae.rhtml?objectType=Attribute&pkId=#{attribute.pkId}"
	end
end

require 'lafcadio/test/LafcadioTestCase'

class TestOption < LafcadioTestCase
	def TestOption.getTestOption
		Option.new( { "attribute" => TestAttribute.getTestAttribute,
				"name" => "option name", "pkId" => 1 } )
	end

	def TestOption.storedTestOption
		opt = getTestOption
		opt.attribute = TestAttribute.storedTestAttribute
		Context.instance.getObjectStore.commit opt
		opt
	end
end
require 'lafcadio/domain'
require '../test/mock/domain'
require 'lafcadio/objectField'

class Option < Lafcadio::DomainObject
	def addEditHomepage
		"admin/ae.rhtml?objectType=Attribute&pk_id=#{attribute.pk_id}"
	end
end

require 'lafcadio/test'

class TestOption < LafcadioTestCase
	def TestOption.getTestOption
		Option.new( { "attribute" => TestAttribute.getTestAttribute,
				"name" => "option name", "pk_id" => 1 } )
	end

	def TestOption.storedTestOption
		opt = getTestOption
		opt.attribute = TestAttribute.storedTestAttribute
		Context.instance.get_object_store.commit opt
		opt
	end
end
require 'lafcadio/domain/DomainObject'
require 'lafcadio/objectField/ImageField'
require 'lafcadio/objectField/SortOrderField'
require 'test/mock/domain/Attribute'
require 'lafcadio/objectField/LinkField'

class Option < DomainObject
	def Option.classFields(fieldSet = "default")
		attributeField = LinkField.new self, Attribute
		attributeField.newDuringEdit = false
		nameField = TextField.new self, "name"
		imageField = ImageField.new self
		imageField.notNull = false
		sortOrderField = SortOrderField.new self
		sortOrderField.sortWithin = Attribute
		[ attributeField, nameField, imageField, sortOrderField ]
	end

	def addEditHomepage
		"admin/ae.rhtml?objectType=Attribute&objId=#{attribute.objId}"
	end
end

require 'lafcadio/test/LafcadioTestCase'

class TestOption < LafcadioTestCase
	def TestOption.getTestOption
		Option.new( { "attribute" => TestAttribute.getTestAttribute,
				"name" => "option name", "objId" => 1, "sortOrder" => 1 } )
	end

	def TestOption.storedTestOption
		opt = getTestOption
		opt.attribute = TestAttribute.storedTestAttribute
		Context.instance.getObjectStore.addObject opt
		opt
	end
end
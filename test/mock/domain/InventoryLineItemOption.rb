require 'lafcadio/domain/MapObject'
require 'test/mock/domain/InventoryLineItem'

class InventoryLineItemOption < MapObject
	def InventoryLineItemOption.classFields
		lineItem = LinkField.new self, InventoryLineItem
		option = LinkField.new self, Option
		option.dbFieldName = 'optionId'
		[ lineItem, option ]
	end

	def InventoryLineItemOption.mappedTypes
		[ InventoryLineItem, Option ]
	end
end

require 'lafcadio/test/LafcadioTestCase'

class TestInventoryLineItemOption < LafcadioTestCase
	def TestInventoryLineItemOption.storedTestInventoryLineItemOption
		fieldHash = { 'inventoryLineItem' =>
											TestInventoryLineItem.storedTestInventoryLineItem,
									'option' => TestOption.storedTestOption }
		ilio = InventoryLineItemOption.new fieldHash
		Context.instance.getObjectStore.addObject ilio
		ilio
	end
end
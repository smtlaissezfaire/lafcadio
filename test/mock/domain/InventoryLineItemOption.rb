require 'lafcadio/domain/MapObject'
require 'test/mock/domain/InventoryLineItem'
require 'test/mock/domain/Option'

class InventoryLineItemOption < MapObject
	def InventoryLineItemOption.mappedTypes
		[ InventoryLineItem, Option ]
	end
end

require 'lafcadio/test/LafcadioTestCase'

class TestInventoryLineItemOption < LafcadioTestCase
	def TestInventoryLineItemOption.getTestInventoryLineItemOption
		fieldHash = { 'objId' => 1, 'inventoryLineItem' =>
											TestInventoryLineItem.getTestInventoryLineItem,
									'option' => TestOption.getTestOption }
		InventoryLineItemOption.new fieldHash
	end

	def TestInventoryLineItemOption.storedTestInventoryLineItemOption
		ilio = TestInventoryLineItemOption.getTestInventoryLineItemOption
		ilio.inventoryLineItem = TestInventoryLineItem.storedTestInventoryLineItem
		ilio.option = TestOption.storedTestOption
		Context.instance.getObjectStore.addObject ilio
		ilio
	end
end
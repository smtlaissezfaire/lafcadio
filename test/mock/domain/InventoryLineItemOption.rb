require 'lafcadio/domain'
require '../test/mock/domain/InventoryLineItem'
require '../test/mock/domain/Option'

class InventoryLineItemOption < Lafcadio::MapObject
	def InventoryLineItemOption.mappedTypes
		[ InventoryLineItem, Option ]
	end
end

require 'lafcadio/test'

class TestInventoryLineItemOption < LafcadioTestCase
	def TestInventoryLineItemOption.getTestInventoryLineItemOption
		fieldHash = { 'pkId' => 1, 'inventoryLineItem' =>
											TestInventoryLineItem.getTestInventoryLineItem,
									'option' => TestOption.getTestOption }
		InventoryLineItemOption.new fieldHash
	end

	def TestInventoryLineItemOption.storedTestInventoryLineItemOption
		ilio = TestInventoryLineItemOption.getTestInventoryLineItemOption
		ilio.inventoryLineItem = TestInventoryLineItem.storedTestInventoryLineItem
		ilio.option = TestOption.storedTestOption
		Context.instance.get_object_store.commit ilio
		ilio
	end
end
require 'lafcadio/domain'

class InventoryLineItem < Lafcadio::DomainObject
end

require 'runit/testcase'
require '../test/mock/domain/SKU'

class TestInventoryLineItem < RUNIT::TestCase
	def TestInventoryLineItem.getTestInventoryLineItem
		InventoryLineItem.new({ 'pk_id' => 1, 'sku' => TestSKU.getTestSKU })
	end

	def TestInventoryLineItem.storedTestInventoryLineItem
		ili = TestInventoryLineItem.getTestInventoryLineItem
		ili.sku = TestSKU.storedTestSKU
		Lafcadio::ObjectStore.get_object_store.commit ili
		ili
	end
end
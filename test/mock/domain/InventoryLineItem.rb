require 'lafcadio/domain/DomainObject'

class InventoryLineItem < DomainObject
end

require 'runit/testcase'
require 'test/mock/domain/SKU'

class TestInventoryLineItem < RUNIT::TestCase
	def TestInventoryLineItem.getTestInventoryLineItem
		InventoryLineItem.new({ 'objId' => 1, 'sku' => TestSKU.getTestSKU })
	end

	def TestInventoryLineItem.storedTestInventoryLineItem
		ili = TestInventoryLineItem.getTestInventoryLineItem
		ili.sku = TestSKU.storedTestSKU
		Context.instance.getObjectStore.addObject ili
		ili
	end
end
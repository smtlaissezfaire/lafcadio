require 'lafcadio/domain/DomainObject'

class InventoryLineItem < DomainObject
	def InventoryLineItem.classFields(fieldSet = 'default')
		require 'lafcadio/objectField/LinkField'
		require 'test/mock/domain/SKU'
		require 'lafcadio/objectField/IntegerField'
		sku = LinkField.new self, SKU
		count = IntegerField.new self, 'count'
		count.default = 0
		[ sku, count ]
	end
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
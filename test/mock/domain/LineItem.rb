require 'lafcadio/domain/DomainObject'

module Domain
	class LineItem < DomainObject
		def LineItem.classFields (fieldSet = 'default')
			require 'test/mock/domain/SKU'
			require 'lafcadio/objectField/LinkField'
			require 'lafcadio/objectField/IntegerField'
			require 'lafcadio/objectField/MoneyField'
			sku = LinkField.new self, SKU
			quantity = IntegerField.new self, 'quantity'
			price = MoneyField.new self, 'price'
			[ sku, quantity, price ]
		end

		def subtotal
			@quantity * @price
		end
	end
end


require 'lafcadio/domain/DomainObject'
require 'lafcadio/util/QueueHash'

class SKU < DomainObject
  def SKU.tableName
    "skus"
  end

  def SKU.classFields (fieldSet = "default")
		require 'lafcadio/objectField/TextField'
		require 'lafcadio/objectField/LinkField'
		require 'lafcadio/objectField/MoneyField'
		require 'lafcadio/objectField/DateField'
    skuField = TextField.new self, "sku", "SKU"
    skuField.size = 16
    skuField.unique = true
    standardPriceField = MoneyField.new self, "standardPrice"
    descField = TextField.new self, "description"
    descField.notNull = false
		salePrice = MoneyField.new self, "salePrice"
		salePrice.notNull = false
		onSaleUntil = DateField.new self, "onSaleUntil"
		onSaleUntil.notNull = false
		sizeField = TextField.new self, 'size'
		sizeField.notNull = false
    [ skuField, standardPriceField, descField, sizeField, salePrice,
			onSaleUntil ]
  end

  def SKU.englishName
		"SKU"
	end

	def SKU.addEditButtons (fieldManager)
		aeButtons = QueueHash.new
		aeButtons["Add another product"] = "cgi-bin/addEdit.rb?objectType=Product"
		aeButtons["Add another SKU"] =
				"cgi-bin/addEdit.rb?objectType=SKU&" +
				"product=#{fieldManager.get('product')}"
		aeButtons["Submit"] = "admin/catalogMgmt.rhtml"
		aeButtons
	end

	def productNamePlusDescription
		productNamePlusDescription = product.name
		if description != nil
			productNamePlusDescription += " - #{description}"
		end
		productNamePlusDescription
	end

	def onSale
		salePrice != nil && onSaleUntil != nil && Date.today <= onSaleUntil
	end

	def price
		if onSale
			salePrice
		else
			standardPrice
		end
	end

	def name
		sku
	end
end

require 'runit/testcase'

class TestSKU < RUNIT::TestCase
	def TestSKU.storedTestSKU
		sku = SKU.new ({ 'sku' => 'sku0001', 'standardPrice' => 99.95 })
		Context.instance.getObjectStore.addObject sku
		sku
	end
end
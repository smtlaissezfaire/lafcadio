require 'lafcadio/domain'
require 'lafcadio/util'

class SKU < Lafcadio::DomainObject
  def SKU.tableName
    "skus"
  end

  def SKU.englishName
		"SKU"
	end

	def SKU.addEditButtons(fieldManager)
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
	def TestSKU.getTestSKU
		SKU.new({ 'pkId' => 1, 'sku' => 'sku0001', 'standardPrice' => 99.95 })
	end

	def TestSKU.storedTestSKU
		sku = TestSKU.getTestSKU
		Lafcadio::Context.instance.get_object_store.commit sku
		sku
	end
end
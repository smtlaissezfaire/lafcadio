require 'lafcadio/objectField'
require 'lafcadio/domain'
require 'lafcadio/test'

class Attribute < Lafcadio::DomainObject
	def Attribute.table_name
		"attributes"
	end

	def Attribute.additionalHeaderFieldNames
		[ "Options" ]
	end

	def Attribute.otherTypesToDisplay
		[ Option ]
	end

	def Attribute.addEditHomepage
		"admin/attributes.rhtml"
	end
end

class Client < Lafcadio::DomainObject
	include Lafcadio
	
  def Client.getTestClient
    Client.new( { "name" => "clientName1", 'pk_id' => 1 } )
  end

	def Client.storedTestClient
		client = Client.getTestClient
		ObjectStore.get_object_store.commit client
		client
	end

  def testPkId
    client = Client.new( { "name" => "clientName1", "pk_id" => 1 } )
    assert_equal(1, client.pk_id)
  end

  def testEquality
    dbd = "clientName1"
    client1 = Client.new( { "name" => dbd, "pk_id" => 1 } )
    client2 = Client.new( { "name" => dbd, "pk_id" => 1 } )
    assert_equal(client1, client2)
  end
end

class DiffSqlPrimaryKey < Lafcadio::DomainObject
	def self.get_class_fields
		super.concat( [ Lafcadio::TextField.new( self, 'text' ) ] )
	end
	
	sql_primary_key_name 'objId'
end

module Domain
	class LineItem < Lafcadio::DomainObject
		def subtotal
			@quantity * @price
		end
	end
end

class InternalClient < Client; end

class InventoryLineItem < Lafcadio::DomainObject; end

class InventoryLineItemOption < Lafcadio::MapObject
	def InventoryLineItemOption.mappedTypes
		[ InventoryLineItem, Option ]
	end
end

class Invoice < Lafcadio::DomainObject
	include Lafcadio

  def Invoice.getTestInvoice
    hash = { "client" => Client.getTestClient, "rate" => 70,
             "date" => Date.new(2001, 4, 5), "hours" => 36.5, 
						 "invoice_num" => 1, "pk_id" => 1 }
    Invoice.new hash
  end

	def Invoice.storedTestInvoice
		inv = Invoice.getTestInvoice
		inv.client = Client.storedTestClient
		ObjectStore.get_object_store.commit inv
		inv
	end

  def name; pk_id.to_s; end
end

class NoXml < Lafcadio::DomainObject
	def NoXml.get_class_fields; super; end
	
	sql_primary_key_name 'no_xml_id'
end

class Option < Lafcadio::DomainObject
	def addEditHomepage
		"admin/ae.rhtml?objectType=Attribute&pk_id=#{attribute.pk_id}"
	end
end

class SKU < Lafcadio::DomainObject
  def SKU.table_name
    "skus"
  end

  def SKU.english_name
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

class TestAttribute < LafcadioTestCase
	def TestAttribute.getTestAttribute
		Attribute.new( { "pk_id" => 1, "name" => "attribute name" })
	end

	def TestAttribute.storedTestAttribute
		att = getTestAttribute
		ObjectStore.get_object_store.commit att
		att
	end
end

class TestInventoryLineItem
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

class TestInventoryLineItemOption < LafcadioTestCase
	def TestInventoryLineItemOption.getTestInventoryLineItemOption
		fieldHash = { 'pk_id' => 1, 'inventoryLineItem' =>
											TestInventoryLineItem.getTestInventoryLineItem,
									'option' => TestOption.getTestOption }
		InventoryLineItemOption.new fieldHash
	end

	def TestInventoryLineItemOption.storedTestInventoryLineItemOption
		ilio = TestInventoryLineItemOption.getTestInventoryLineItemOption
		ilio.inventoryLineItem = TestInventoryLineItem.storedTestInventoryLineItem
		ilio.option = TestOption.storedTestOption
		ObjectStore.get_object_store.commit ilio
		ilio
	end
end

class TestOption < LafcadioTestCase
	def TestOption.getTestOption
		Option.new( { "attribute" => TestAttribute.getTestAttribute,
				"name" => "option name", "pk_id" => 1 } )
	end

	def TestOption.storedTestOption
		opt = getTestOption
		opt.attribute = TestAttribute.storedTestAttribute
		ObjectStore.get_object_store.commit opt
		opt
	end
end

class TestSKU
	def TestSKU.getTestSKU
		SKU.new({ 'pk_id' => 1, 'sku' => 'sku0001', 'standardPrice' => 99.95 })
	end

	def TestSKU.storedTestSKU
		sku = TestSKU.getTestSKU
		Lafcadio::ObjectStore.get_object_store.commit sku
		sku
	end
end

class User < Lafcadio::DomainObject
  def User.fieldHash
    fieldHash = { "salutation" => "Mr", "firstNames" => "Francis",
		  "lastName" => "Hwang", "phone" => "", "address1" => "",
		  "address2" => "", "city" => "", "state" => "", "zip" => "",
		  "email" => "test@test.com", "password" => "mypassword!" }
  end

  def User.getTestUser
		User.new fieldHash
  end

  def User.getTestUserWithPkId
    myHash = fieldHash
    myHash["pk_id"] = 1
    user = User.new myHash
		Context.instance.getObjectStore.commit user
		user
  end
end

class XmlSku < Lafcadio::DomainObject; end

class XmlSku2 < Lafcadio::DomainObject
	boolean    'boolean1',
	           { 'enum_type' => Lafcadio::BooleanField::ENUMS_CAPITAL_YES_NO }
	boolean    'boolean2',
	           { 'enums' => { true => 'yin', false => 'yang' },
		           'english_name' => 'boolean 2' }
	date       'date1', { 'not_null' => false }
	date       'date2', { 'range' => Lafcadio::DateField::RANGE_PAST }
	dateTime   'dateTime1'
	decimal    'decimal1', { 'precision' => 4, 'english_name' => 'decimal 1' }
	email      'email1'
	enum       'enum1',
	           { 'enums' => Lafcadio::QueueHash.new( 'a', 'a', 'b', 'b' ) }
	enum       'enum2',
	           { 'enums' => Lafcadio::QueueHash.new( '1', '2', '3', '4' ) }
	integer    'integer1'
	link       'link1', { 'linked_type' => User, 'delete_cascade' => true }
	money      'money1'
	month      'month1'
	subsetLink 'subsetLink1', { 'subset_field' => 'xmlSku' }
	text       'text1', { 'size' => 16, 'unique' => true }
	text       'text2', { 'large' => true }
	textList   'textList1', { 'db_field_name' => 'text_list1' }
	timeStamp  'timestamp1'
	
	table_name         'that_table'
	sql_primary_key_name 'xml_sku2_id'
end

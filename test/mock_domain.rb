require 'lafcadio/objectField'
require 'lafcadio/depend'
require 'lafcadio/domain'
require 'lafcadio/test'

class Attribute < Lafcadio::DomainObject
	def self.committed_mock
		att = uncommitted_mock
		ObjectStore.get_object_store.commit att
		att
	end

	def self.table_name; "attributes"; end

	def self.uncommitted_mock
		Attribute.new( { "pk_id" => 1, "name" => "attribute name" })
	end
end

class Client < Lafcadio::DomainObject
	include Lafcadio
	
	def self.committed_mock
		client = uncommitted_mock
		ObjectStore.get_object_store.commit client
		client
	end
	
  def self.uncommitted_mock
    Client.new( "name" => "clientName1", 'pk_id' => 1 )
  end

	def post_commit_trigger
		if (
			self.name == 'Cthulhu' and self.priorityInvoice and
			self.priorityInvoice.client.name == 'Cthulhu'
		)
			raise
		end
	end
end

class DiffSqlPrimaryKey < Lafcadio::DomainObject
	def self.get_class_fields
		super.concat( [ Lafcadio::StringField.new( self, 'text' ) ] )
	end
	
	sql_primary_key_name 'objId'
end

module Domain; class LineItem < Lafcadio::DomainObject; end; end

class DomainObjChild1 < Lafcadio::DomainObject
	default_field_setup_hash Lafcadio::BooleanField,
	                         {
													   'enum_type' =>   Lafcadio::BooleanField::ENUMS_CAPITAL_YES_NO
													 }

	boolean  'bool1'
	boolean  'bool2', { 'enum_type' => Lafcadio::BooleanField::ENUMS_ONE_ZERO }
	booleans 'bool3',
           'bool4', { 'enum_type' => Lafcadio::BooleanField::ENUMS_ONE_ZERO },
	         'bool5'
	strings  'text1', 'text2'
end

class InternalClient < Client; end

class InventoryLineItem < Lafcadio::DomainObject
	def self.committed_mock
		ili = uncommitted_mock
		ili.sku = SKU.committed_mock
		Lafcadio::ObjectStore.get_object_store.commit ili
		ili
	end

	def self.uncommitted_mock
		InventoryLineItem.new({ 'pk_id' => 1, 'sku' => SKU.uncommitted_mock })
	end
end

class InventoryLineItemOption < Lafcadio::MapObject
	def self.committed_mock
		ilio = uncommitted_mock
		ilio.inventory_line_item = InventoryLineItem.committed_mock
		ilio.option = Option.committed_mock
		ObjectStore.get_object_store.commit ilio
		ilio
	end

	def self.uncommitted_mock
		InventoryLineItemOption.new(
			'pk_id' => 1,
			'inventory_line_item' => InventoryLineItem.uncommitted_mock,
			'option' => Option.uncommitted_mock
		)
	end

	def self.mappedTypes; [ InventoryLineItem, Option ]; end
end

class Invoice < Lafcadio::DomainObject
	include Lafcadio

	def self.committed_mock
		inv = uncommitted_mock
		inv.client = Client.committed_mock
		ObjectStore.get_object_store.commit inv
		inv
	end
	
  def self.uncommitted_mock
    Invoice.new(
			"client" => Client.uncommitted_mock, "rate" => 70,
			"date" => Date.new(2001, 4, 5), "hours" => 36.5, "pk_id" => 1
		)
  end

	def name; pk_id.to_s; end
end

class NoXml < Lafcadio::DomainObject
	def NoXml.get_class_fields; super; end
	
	sql_primary_key_name 'no_xml_id'
end

class Option < Lafcadio::DomainObject
	def self.committed_mock
		opt = uncommitted_mock
		opt.attribute = Attribute.committed_mock
		ObjectStore.get_object_store.commit opt
		opt
	end

	def self.uncommitted_mock
		Option.new(
			"attribute" => Attribute.uncommitted_mock, "name" => "option name",
			"pk_id" => 1
		)
	end
end

class SKU < Lafcadio::DomainObject
	def self.committed_mock
		sku = uncommitted_mock
		Lafcadio::ObjectStore.get_object_store.commit sku
		sku
	end

  def self.english_name; "SKU"; end

	def self.table_name; "skus"; end

	def self.uncommitted_mock
		SKU.new({ 'pk_id' => 1, 'sku' => 'sku0001', 'standardPrice' => 99.95 })
	end
end

class User < Lafcadio::DomainObject
  def self.committed_mock
		user = User.new(
			"firstNames" => "Francis", "email" => "test@test.com", 'pk_id' => 1
		)
		user.commit
		user
  end

  def self.uncommitted_mock
		User.new( "firstNames" => "Francis", "email" => "test@test.com" )
  end
end

class XmlSku < Lafcadio::DomainObject; end

class XmlSku2 < Lafcadio::DomainObject
	boolean              'boolean1',
	                     { 'enum_type' =>
											     Lafcadio::BooleanField::ENUMS_CAPITAL_YES_NO
											 }
	boolean              'boolean2',
	                     { 'enums' => { true => 'yin', false => 'yang' },
		                     'english_name' => 'boolean 2' }
	date                 'date1', { 'not_null' => false }
	date                 'date2'
	date_time            'dateTime1'
	domain_object        User, 'link1', { 'delete_cascade' => true }
	domain_object        XmlSku
	email                'email1'
	enum                 'enum1',
	                     { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) }
	enum                 'enum2',
	                     { 'enums' => QueueHash.new( '1', '2', '3', '4' ) }
	float                'decimal1',
                       { 'precision' => 4, 'english_name' => 'decimal 1' }
	integer              'integer1'
	month                'month1'
	subset_domain_object 'subsetLink1', { 'subset_field' => 'xmlSku' }
	string               'text1', { 'size' => 16, 'unique' => true }
	string               'text2', { 'large' => true }
	text_list            'textList1', { 'db_field_name' => 'text_list1' }
	time_stamp           'timestamp1'
	
	table_name         'that_table'
	sql_primary_key_name 'xml_sku2_id'
end

class XmlSku3 < Lafcadio::DomainObject
	boolean	'boolean1',
	        { 'enum_type' => Lafcadio::BooleanField::ENUMS_CAPITAL_YES_NO }
	boolean	:boolean2,
	        {
						'enums' => { true => 'yin', false => 'yang' },
						'english_name' => 'boolean 2'
					}

	def self.sql_primary_key_name; 'xml_sku3_id'; end
	
	def self.table_name; 'this_table'; end
end


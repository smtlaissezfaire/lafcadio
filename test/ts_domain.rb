require 'lafcadio/depend'
require 'lafcadio/domain'
require '../test/mock_domain'
require '../test/test_case'

class TestClassDefinitionXmlParser < LafcadioTestCase
	def get_class_fields( domain_class, xml )
		ClassDefinitionXmlParser.new( domain_class, xml ).get_class_fields
	end

	def match_field( domain_class, fieldName, fieldClass, attributes = nil )
		field = domain_class.class_field fieldName
		assert_not_nil( field )
		assert_equal( fieldClass, field.class )
		if attributes
			attributes.each { |attrName, attrValue|
				assert_equal( attrValue, field.send( attrName ) )
			}
		end
	end

	def test_class_fields_from_xml
		XmlSku.class_fields
		match_field(
			XmlSku, 'boolean1', BooleanField, { 'enum_type' => :capital_yes_no }
		)
		match_field( XmlSku, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' } } )
		match_field( XmlSku, 'date1', DateField, { 'not_nil' => false } )
		match_field( XmlSku, 'date2', DateField )
		match_field( XmlSku, 'dateTime1', DateTimeField )
		match_field( XmlSku, 'decimal1', FloatField )
		match_field( XmlSku, 'email1', EmailField )
		match_field( XmlSku, 'enum1', EnumField,
		            { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) } )
		match_field( XmlSku, 'enum2', EnumField,
		            { 'enums' => QueueHash.new( '1', '2', '3', '4' ) } )
		match_field( XmlSku, 'integer1', IntegerField )
		match_field( XmlSku, 'link1', DomainObjectField,
		            { 'linked_type' => User, 'delete_cascade' => true } )
		match_field( XmlSku, 'link2', DomainObjectField,
		            { 'linked_type' => Invoice, 'db_field_name' => 'an_invoice' } )
		match_field( XmlSku, 'month1', MonthField )
		match_field( XmlSku, 'subsetLink1', SubsetDomainObjectField,
		            { 'subset_field' => 'xmlSku' } )
		match_field( XmlSku, 'text1', StringField )
		match_field( XmlSku, 'text2', StringField )
		match_field( XmlSku, 'textList1', TextListField,
		            { 'db_field_name' => 'text_list1' } )
		match_field( Invoice, 'timestamp1', TimeStampField )
	end
	
	def test_field_names_need_to_be_unique
		begin
			get_class_fields( XmlSku, <<-XML
				<lafcadio_class_definition name="XmlSku">
					<field name="date1" class="DateField" not_nil="n"/>
					<field name="date1" class="DateField"/>
				</lafcadio_class_definition>
			XML
			)
			raise "needs to throw an error if there are two names the same"
		rescue ClassDefinitionXmlParser::InvalidDataError
			# desired behavior
		end
	end

	def test_set_pk_name_and_table_name_in_xml
		assert_equal( 'some_other_id', XmlSku.sql_primary_key_name )
		assert_equal( 'pk_id', Attribute.sql_primary_key_name )
		assert_equal( 'some_other_table', XmlSku.table_name )
		assert_equal( 'attributes', Attribute.table_name )
	end

	def test_useful_error_messages
		begin
			get_class_fields( XmlSku, <<-XML
				<lafcadio_class_definition name="XmlSku">
					<field name="date1" not_nil="n"/>
				</lafcadio_class_definition>
			XML
			)
			fail "Should've thrown a StandardError"
		rescue StandardError
			assert_equal( "Couldn't find field class '' for field 'date1'", $!.to_s )
		end
	end
end

class TestDomainComparable < LafcadioTestCase
	def testComparableToNil
		client = Client.committed_mock
		assert( !( client == nil ) )
	end
end

# necessary for test_global_methods_dont_interfere_with_method_missing
def name; 'global name'; end

class Client < Lafcadio::DomainObject
	# used in test_refresh_original_values_after_commit
	attr_accessor :original_values
end

class TestDomainObject < LafcadioTestCase
	def teardown
		super
		LafcadioConfig.set_values( nil )
		if FileTest.exist?( '../test/testData/Attribute.xml.tmp' )
			`mv ../test/testData/Attribute.xml.tmp ../test/testData/Attribute.xml`
		end
		def Attribute.post_commit_trigger( att ); end
	end

	def match_field( domain_class, fieldName, fieldClass, attributes = nil )
		field = domain_class.class_field fieldName
		assert_not_nil( field )
		assert_equal( fieldClass, field.class )
		if attributes
			attributes.each { |attrName, attrValue|
				assert_equal( attrValue, field.send( attrName ) )
			}
		end
	end
	
	def new_test_client_without_pk_id; Client.new( "name" => "clientName" ); end

	def test_assigns_proxies
		invoice = Invoice.committed_mock
		assert_equal 1, invoice.client.pk_id
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2' })
		invoice.client = client2
		client2Proxy = invoice.client
		assert_equal DomainObjectProxy, client2Proxy.class
		assert_equal 2, client2Proxy.pk_id
		invoice.client = nil
		assert_nil invoice.client
	end

	def test_caches_class_fields
		2.times { MockDomainObject.class_fields }
	end
	
	def test_checks_fields_at_all_states
		LafcadioConfig.set_values(
			'checkFields' => 'onAllStates',
			'classDefinitionDir' => '../test/testData'
		)
		client = Client.new( 'name' => 'client name' )
		assert_raise( FieldValueError ) { client.name = nil }
		assert_raise( FieldValueError ) { Client.new( 'name' => nil ) }
	end

	def test_checks_fields_on_commit
		LafcadioConfig.set_values(
			'checkFields' => 'onCommit', 'classDefinitionDir' => '../test/testData'
		)
		client = Client.new( {} )
		assert_raise( FieldValueError ) { client.commit }
	end

	def test_checks_fields_on_instantiation
		LafcadioConfig.set_values(
			'checkFields' => 'onInstantiate',
			'classDefinitionDir' => '../test/testData'
		)
		first_client = Client.new( 'name' => 'first client' ).commit
		assert_raise( FieldValueError ) { Client.new( {} ) }
		assert_raise( FieldValueError ) {
			Client.new(
				'name' => 'client name', 'referringClient' => first_client,
				'notes' => 123
			)
		}
		assert_raise( FieldValueError ) {
			Client.new( 'name' => 'client name', 'referringClient' => first_client,
			            'standard_rate' => "Free!" )
		}
		assert_raise( FieldValueError ) {
			User.new( 'email' => 'a@a', 'firstNames' => 'Bill',
			          'administrator' => false )
		}
		assert_raise( FieldValueError ) {
			XmlSku.new( 'enum1' => 'c', 'email1' => 'bill@bill.bill' )
		}
		assert_raise( FieldValueError ) {
			XmlSku.new( 'textList1' => 'a,b,c', 'email1' => 'bill@bill.bill',
			            'enum1' => 'a', 'enum2' => '1' )
		}
	end
	
	def test_class_fields_from_one_line_class_methods
		XmlSku2.class_fields
		match_field(
			XmlSku2, 'boolean1', BooleanField, { 'enum_type' => :capital_yes_no }
		)
		match_field( XmlSku2, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' } } )
		match_field( XmlSku2, 'date1', DateField, { 'not_nil' => false } )
		match_field( XmlSku2, 'date2', DateField )
		match_field( XmlSku2, 'dateTime1', DateTimeField )
		match_field( XmlSku2, 'decimal1', FloatField )
		match_field( XmlSku2, 'email1', EmailField )
		match_field( XmlSku2, 'enum1', EnumField,
		            { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) } )
		match_field( XmlSku2, 'enum2', EnumField,
		            { 'enums' => QueueHash.new( '1', '2', '3', '4' ) } )
		match_field( XmlSku2, 'integer1', IntegerField )
		match_field( XmlSku2, 'link1', DomainObjectField,
		            { 'linked_type' => User, 'delete_cascade' => true } )
		match_field( XmlSku2, 'month1', MonthField )
		match_field( XmlSku2, 'subsetLink1', SubsetDomainObjectField,
		            { 'subset_field' => 'xmlSku' } )
		match_field( XmlSku2, 'text1', StringField )
		match_field( XmlSku2, 'text2', StringField )
		match_field( XmlSku2, 'textList1', TextListField,
		            { 'db_field_name' => 'text_list1' } )
		match_field( XmlSku2, 'timestamp1', TimeStampField )
	end
	
	def test_class_fields_named_as_symbols
		match_field(
			XmlSku3, 'boolean2', BooleanField,
			{ 'enums' => { true => 'yin', false => 'yang' } }
		)
	end
	
	def test_class_fields_plural
		match_field( DomainObjChild1, 'bool3', BooleanField )
		match_field(
			DomainObjChild1, 'bool4', BooleanField, { 'enum_type' => :one_zero }
		)
		match_field( DomainObjChild1, 'bool5', BooleanField )
		match_field( DomainObjChild1, 'text1', StringField )
		match_field( DomainObjChild1, 'text2', StringField )
	end
	
	def test_clone
		client1 = new_test_client_without_pk_id
		client2 = client1.clone
		client2.name = 'client 2 name'
		assert_equal 'clientName', client1.name
	end
	
	def test_commit
		assert_equal 0, @mockObjectStore.all(Client).size
		client = new_test_client_without_pk_id
		something = client.commit
		assert_equal 1, @mockObjectStore.all(Client).size
		assert_equal( Client, something.class )
	end
	
	def test_convenience_class_methods
		5.times { Client.new({}).commit }
		assert_equal( 5, Client.all.size )
		assert Client.exist?( 1 )
		assert !Client.exist?( 100 )
		cli = Client.first
		cli.name = "new name"
		cli.commit
		assert Client.exist?( 'new name', 'name' )
		assert Client.exist?( 'new name', :name )
		assert_equal( 1, Client.first.pk_id )
		assert_equal( 5, Client.last.pk_id )
		assert_raise( IndexError ) { Client.only }
		assert_equal( 3, Client[3].pk_id )
	end
	
	def test_count
		3.times do Client.new( 'name' => 'name' ).commit; end
		assert_equal( 3, Client.get( :group => :count ).only[:count] )
	end
	
	def test_create_with_linked_proxies
		clientProxy = DomainObjectProxy.new Client, 99
		invoice = Invoice.new(
			'client' => clientProxy, 'rate' => 70, 'date' => Date.new(2001, 4, 5),
			'hours' => 36.5, 'pk_id' => 1
		)
		proxyPrime = invoice.client
		assert_attributes(
			proxyPrime,
			{ :class => DomainObjectProxy, :domain_class => Client, :pk_id => 99 }
		)
		assert_raise( DomainObjectNotFoundError ) { proxyPrime.name }
		client = Client.uncommitted_mock
    client.pk_id = 99
    @mockObjectStore.commit client
		assert_equal client.name, proxyPrime.name
	end

	def test_cyclical_marshal
		client = Client.uncommitted_mock
		invoice = Invoice.uncommitted_mock
		client.priorityInvoice = invoice
		invoice.client = client
		@mockObjectStore.commit client
		@mockObjectStore.commit invoice
		data = Marshal.dump client
		clientPrime = Marshal.load data
		assert_equal client, clientPrime.priorityInvoice.client
	end

	def test_default_field_setup_hash
		assert_equal( :capital_yes_no, DomainObjChild1.field( 'bool1' ).enum_type )
		assert_equal( :one_zero, DomainObjChild1.field( 'bool2' ).enum_type )
	end

	def test_defers_field_copying
		xml_sku_row_hash = OneTimeAccessHash.new( 'some_other_id' => '345' )
		xml_sku_converter = ObjectStore::SqlToRubyValues.new(
			XmlSku, xml_sku_row_hash
		)
		xml_sku = XmlSku.new( xml_sku_converter )
		assert_equal( 345, xml_sku.pk_id )
	end
	
  def test_defines_setters
    client = new_test_client_without_pk_id
    assert_equal("clientName", client.name)
    client.name = "newClientName"
    assert_equal("newClientName", client.name)
  end

	def test_delete!
		client = Client.new( {} ).commit
		assert_equal( 1, Client.all.size )
		client.delete!
		assert_equal( 0, Client.all.size )
	end
	
	def test_dispatch_to_object_store
		invoice = Invoice.committed_mock
		client = Client.committed_mock
		assert_equal( invoice, client.invoices.only )
		assert_equal( 0, client.clients( 'referringClient' ).size )
		client2 = Client.new( 'pk_id' => 2, 'referringClient' => client )
		client2.commit
		assert_equal( client2, client.clients( 'referringClient' ).only )
		assert_equal( client, Client.get( 1 ) )
		assert_equal(
			client2,
			Client.get { |cli| cli.referringClient.equals( client ) }.only
		)
		assert_equal( client2, Client.get( client, 'referringClient').only )
	end
	
	def test_dont_set_delete_without_pk_id
		foo = Client.new( { "name" => "clientName1" } )
		begin
			foo.delete = 1
			fail "You can't delete something that hasn't been committed"
		rescue
			# fine
		end
	end

  def test_dumpable
    client = new_test_client_without_pk_id
    data = Marshal.dump client
    newClient = Marshal.load data
		assert_attributes( newClient, { :class => Client, :pk_id => nil } )
		client2 = Client.uncommitted_mock
		assert_equal 1, client2.pk_id
		@mockObjectStore.commit client2
		data2 = Marshal.dump client2
		newClient2 = Marshal.load data2
		assert_equal 1, newClient2.pk_id
		coll = [ client, client2 ]
		collData = Marshal.dump coll
		collPrime = Marshal.load collData
		assert_equal nil, collPrime[0].pk_id
		assert_equal 1, collPrime[1].pk_id
  end

	def test_equality
		client = Client.uncommitted_mock
		clientPrime = Client.uncommitted_mock
		assert_equal client, clientPrime
		assert( client.eql?( clientPrime ) )
		invoice = Invoice.uncommitted_mock
		assert_equal 1, invoice.pk_id
		assert_equal 1, client.pk_id
		assert invoice != client
	end
	
	def test_fails_if_bad_hash
		assert_raise( ArgumentError ) {
			Client.new( 'not-a-field' => 'something' )
		}
	end

	def test_get_field
		name = Client.class_field 'name'
		assert_not_nil name
		assert_equal( 'name', InternalClient.field( 'name' ).name )
		assert_equal( 'billingType', InternalClient.field( 'billingType' ).name )
		assert_nil InternalClient.field( 'something' )
	end
	
	def test_global_methods_dont_interfere_with_method_missing
		c = Client.new( 'name' => 'client name' )
		assert_equal( 'client name', c.name )
		assert_equal( 'client name', c.send( :name ) )
	end
	
	def test_handles_class_without_xml
		assert_equal( 'no_xml_id', NoXml.sql_primary_key_name )
		assert_equal( 'no_xmls', NoXml.table_name )
	end
	
	def test_hash_and_eql
		client = Client.new( 'pk_id' => 1, 'name' => 'client name' )
		client_prime = Client.new( 'pk_id' => 1, 'name' => 'client name' )
		assert_equal( client.hash, client_prime.hash )
		assert( client.eql?( client_prime ) )
		assert( client_prime.eql?( client ) )
		client2 = Client.new( 'pk_id' => 2, 'name' => 'someone else' )
		assert( !client.eql?( client2 ) )
	end
	
	def test_informative_error_if_missing_class_data
		`mv ../test/testData/Attribute.xml ../test/testData/Attribute.xml.tmp`
		begin
			Attribute.get_class_fields
			fail "Definitely needs to raise an Exception"
		rescue MissingError
			assert_equal( "Couldn't find either an XML class description file or " +
			              "get_class_fields method for Attribute", $!.to_s )
		end
	end

	def test_inheritance
		ic = InternalClient.new({ 'name' => 'clientName1',
				'billingType' => 'trade' })
		assert_equal 'clientName1', ic.name
		assert_equal 'trade', ic.billingType
	end
	
	def test_map_object
		assert_equal( [], MapObject.get_class_fields )
	end
	
	def test_method_missing
		begin
			Client.foobar
			fail "Should raise NoMethodError"
		rescue NoMethodError => err
			assert_equal( "undefined method `foobar' for Client:Class", err.to_s )
		end
	end
	
	def test_new_with_strings_or_symbols
		client1 = Client.new( 'name' => 'client 1' )
		assert_equal( 'client 1', client1.name )
		client2 = Client.new( :name => 'client 2' )
		assert_equal( 'client 2', client2.name )
	end
	
	def test_object_links_update_live
		invoice = Invoice.committed_mock
		client = Client.committed_mock
		assert_equal client, invoice.client
		assert_equal client.name, invoice.client.name
		client.name = 'new name'
		@mockObjectStore.commit client
		assert_equal client.name, invoice.client.name
	end
	
	def test_one_liners_only_create_fields_once
		assert_equal( 19, XmlSku2.class_fields.size )
		require '../test/../test/mock_domain'
		assert_equal( 19, XmlSku2.class_fields.size )
	end
	
	def test_original_values_accessible_in_triggers
		att1 = Attribute.new( 'name' => 'original name' )
		def att1.post_commit_trigger
			raise if self.name != @original_values['name']
		end
		att1.commit
		att1.name = 'something else'
		assert_raise( RuntimeError ) do att1.commit; end
		att2 = Attribute.new( 'name' => 'Cthulhu' )
		def att2.post_commit_trigger
			raise if @original_values['name'] == 'Cthulhu'
		end
		assert_raise( RuntimeError ) do att2.commit; end
		att2.name = 'something else'
		assert_raise( RuntimeError ) do att2.commit; end
		def att2.post_commit_trigger; @original_values['name'] = 'foobar'; end
		assert_raise( NoMethodError ) do att2.commit; end
	end
	
	def test_override_class_defaults
		assert_equal( 'this_table', XmlSku3.table_name )
		assert_equal( 'xml_sku3_id', XmlSku3.sql_primary_key_name )
		assert_equal( 'xml_sku3_id', XmlSku3.field( 'pk_id' ).db_field_name )
	end

	def test_override_class_defaults_from_one_liners
		assert_equal( 'that_table', XmlSku2.table_name )
		assert_equal( 'xml_sku2_id', XmlSku2.sql_primary_key_name )
	end
	
	def test_pk_id_needs_fixnum
		assert_equal Fixnum, Client.uncommitted_mock.pk_id.class
	end
	
	def test_postgres_pk_id_seq
		assert_equal( 'users_pk_id_seq', User.postgres_pk_id_seq )
		assert_equal( 'that_table_xml_sku2_id_seq', XmlSku2.postgres_pk_id_seq )
	end

	def test_refresh_original_values_after_commit
		client = Client.new( 'name' => 'text' ).commit
		assert_equal( 'text', client.original_values['name'] )
		client.name = 'something else'
		assert_equal( 'text', client.original_values['name'] )
		client.commit
		assert_equal( 'something else', client.original_values['name'] )
	end

	def test_sql_primary_key_name
		assert_equal( DiffSqlPrimaryKey.sql_primary_key_name,
		              DiffSqlPrimaryKey.get_class_fields.first.db_field_name )
	end

	def test_table_name
		assert_equal( "users", User.table_name )
		assert_equal( "line_items", Domain::LineItem.table_name )
	end
	
	def test_to_s
		assert_match( /Client/, new_test_client_without_pk_id.to_s )
	end
	
	def test_try_load_xml_parser
		LafcadioConfig.set_values( {} )
		assert_nil Client.try_load_xml_parser
	end

	def test_update!
		client = Client.new( {} ).commit
		assert_equal( nil, Client.first.name )
		client.update!( :name => 'new name' )
		assert_equal( 'new name', Client.first.name )
	end
	
	class MockDomainObject < DomainObject
		@@classesInstantiated = false
		
		def MockDomainObject.get_class_fields
			raise "should be cached" if @@classesInstantiated
			@@classesInstantiated = true
			[]
		end
	end

	class OneTimeAccessHash < DelegateClass( Hash )
		attr_reader :key_lookups
	
		def initialize( hash )
			super( hash )
			@key_lookups = Hash.new( 0 )
		end
		
		def []( key )
			@key_lookups[key] += 1
			raise "Should only access #{ key } once" if @key_lookups[key] > 1
			super( key )
		end
	end
end
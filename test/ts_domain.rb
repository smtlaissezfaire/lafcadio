require 'lafcadio/test'
require 'lafcadio/domain'
require '../test/mock/domain'

class TestClassDefinitionXmlParser < LafcadioTestCase
	def get_class_fields( domain_class, xml )
		ClassDefinitionXmlParser.new( domain_class, xml ).get_class_fields
	end

	def matchField( domain_class, fieldName, fieldClass, attributes = nil )
		field = domain_class.get_class_field( fieldName )
		assert_not_nil( field )
		assert_equal( fieldClass, field.class )
		if attributes
			attributes.each { |attrName, attrValue|
				assert_equal( attrValue, field.send( attrName ) )
			}
		end
	end

	def testClassFieldsFromXml
		require 'lafcadio/objectField'
		XmlSku.class_fields
		matchField( XmlSku, 'boolean1', BooleanField,
		            { 'enum_type' => BooleanField::ENUMS_CAPITAL_YES_NO } )
		matchField( XmlSku, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' } } )
		matchField( XmlSku, 'date1', DateField, { 'not_null' => false } )
		matchField( XmlSku, 'date2', DateField )
		matchField( XmlSku, 'dateTime1', DateTimeField )
		matchField( XmlSku, 'decimal1', DecimalField )
		matchField( XmlSku, 'email1', EmailField )
		matchField( XmlSku, 'enum1', EnumField,
		            { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) } )
		matchField( XmlSku, 'enum2', EnumField,
		            { 'enums' => QueueHash.new( '1', '2', '3', '4' ) } )
		matchField( XmlSku, 'integer1', IntegerField )
		matchField( XmlSku, 'link1', LinkField,
		            { 'linked_type' => User, 'delete_cascade' => true } )
		matchField( XmlSku, 'link2', LinkField,
		            { 'linked_type' => Invoice, 'db_field_name' => 'an_invoice' } )
		matchField( XmlSku, 'month1', MonthField )
		matchField( XmlSku, 'subsetLink1', SubsetLinkField,
		            { 'subset_field' => 'xmlSku' } )
		matchField( XmlSku, 'text1', TextField )
		matchField( XmlSku, 'text2', TextField )
		matchField( XmlSku, 'textList1', TextListField,
		            { 'db_field_name' => 'text_list1' } )
		matchField( Invoice, 'timestamp1', TimeStampField )
	end
	
	def testFieldNamesNeedToBeUnique
		begin
			get_class_fields( XmlSku, <<-XML
				<lafcadio_class_definition name="XmlSku">
					<field name="date1" class="DateField" not_null="n"/>
					<field name="date1" class="DateField"/>
				</lafcadio_class_definition>
			XML
			)
			raise "needs to throw an error if there are two names the same"
		rescue ClassDefinitionXmlParser::InvalidDataError
			# desired behavior
		end
	end

	def testSetPkNameAndTableNameInXml
		assert_equal( 'some_other_id', XmlSku.sql_primary_key_name )
		assert_equal( 'pk_id', Attribute.sql_primary_key_name )
		assert_equal( 'some_other_table', XmlSku.table_name )
		assert_equal( 'attributes', Attribute.table_name )
	end

	def testUsefulErrorMessages
		begin
			get_class_fields( XmlSku, <<-XML
				<lafcadio_class_definition name="XmlSku">
					<field name="date1" not_null="n"/>
				</lafcadio_class_definition>
			XML
			)
			fail "Should've thrown a StandardError"
		rescue StandardError
			assert_equal( "Couldn't find field class '' for field 'date1'", $!.to_s )
		end
	end
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

	def matchField( domain_class, fieldName, fieldClass, attributes = nil )
		field = domain_class.get_class_field( fieldName )
		assert_not_nil( field )
		assert_equal( fieldClass, field.class )
		if attributes
			attributes.each { |attrName, attrValue|
				assert_equal( attrValue, field.send( attrName ) )
			}
		end
	end
	
	def newTestClientWithoutPkId; Client.new( "name" => "clientName" ); end

	def testAssignProxies
		invoice = Invoice.storedTestInvoice
		assert_equal 1, invoice.client.pk_id
		client2 = Client.new({ 'pk_id' => 2, 'name' => 'client 2' })
		invoice.client = client2
		client2Proxy = invoice.client
		assert_equal DomainObjectProxy, client2Proxy.class
		assert_equal 2, client2Proxy.pk_id
		invoice.client = nil
		assert_nil invoice.client
	end

	def testCachesClassFields
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
		LafcadioConfig.set_values( 'checkFields' => 'onInstantiate',
		                           'classDefinitionDir' => '../test/testData' )
		first_client = Client.new( 'name' => 'first client' )
		first_client.commit
		assert_raise( FieldValueError ) { Client.new( {} ) }
		assert_raise( FieldValueError ) {
			Client.new( 'name' => 'client name', 'referringClient' => first_client,
			            'notes' => 123 )
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
		matchField( XmlSku2, 'boolean1', BooleanField,
		            { 'enum_type' => BooleanField::ENUMS_CAPITAL_YES_NO } )
		matchField( XmlSku2, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' } } )
		matchField( XmlSku2, 'date1', DateField, { 'not_null' => false } )
		matchField( XmlSku2, 'date2', DateField )
		matchField( XmlSku2, 'dateTime1', DateTimeField )
		matchField( XmlSku2, 'decimal1', DecimalField )
		matchField( XmlSku2, 'email1', EmailField )
		matchField( XmlSku2, 'enum1', EnumField,
		            { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) } )
		matchField( XmlSku2, 'enum2', EnumField,
		            { 'enums' => QueueHash.new( '1', '2', '3', '4' ) } )
		matchField( XmlSku2, 'integer1', IntegerField )
		matchField( XmlSku2, 'link1', LinkField,
		            { 'linked_type' => User, 'delete_cascade' => true } )
		matchField( XmlSku2, 'month1', MonthField )
		matchField( XmlSku2, 'subsetLink1', SubsetLinkField,
		            { 'subset_field' => 'xmlSku' } )
		matchField( XmlSku2, 'text1', TextField )
		matchField( XmlSku2, 'text2', TextField )
		matchField( XmlSku2, 'textList1', TextListField,
		            { 'db_field_name' => 'text_list1' } )
		matchField( XmlSku2, 'timestamp1', TimeStampField )
	end
	
	def test_class_fields_named_as_symbols
		matchField(
			XmlSku3, 'boolean2', BooleanField,
			{ 'enums' => { true => 'yin', false => 'yang' } }
		)
	end
	
	def test_class_fields_plural
		matchField( DomainObjChild1, 'bool3', BooleanField )
		matchField(
			DomainObjChild1, 'bool4', BooleanField,
			{ 'enum_type' => BooleanField::ENUMS_ONE_ZERO }
		)
		matchField( DomainObjChild1, 'bool5', BooleanField )
		matchField( DomainObjChild1, 'text1', TextField )
		matchField( DomainObjChild1, 'text2', TextField )
	end
	
	def testClone
		client1 = newTestClientWithoutPkId
		client2 = client1.clone
		client2.name = 'client 2 name'
		assert_equal 'clientName', client1.name
	end
	
	def testCommit
		assert_equal 0, @mockObjectStore.get_all(Client).size
		client = newTestClientWithoutPkId
		something = client.commit
		assert_equal 1, @mockObjectStore.get_all(Client).size
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
	
	def testCreateWithLinkedProxies
		clientProxy = DomainObjectProxy.new Client, 99
		invoice = Invoice.new(
			'client' => clientProxy, 'rate' => 70, 'date' => Date.new(2001, 4, 5),
			'hours' => 36.5, 'pk_id' => 1
		)
		proxyPrime = invoice.client
		assert_equal DomainObjectProxy, proxyPrime.class
		assert_equal Client, proxyPrime.domain_class
		assert_equal 99, proxyPrime.pk_id
		begin
			proxyPrime.name
			fail "should throw DomainObjectNotFoundError"
		rescue DomainObjectNotFoundError
			# ok
		end
		client = Client.getTestClient
    client.pk_id = 99
    @mockObjectStore.commit client
		assert_equal client.name, proxyPrime.name
	end

	def testCyclicalMarshal
		client = Client.getTestClient
		invoice = Invoice.getTestInvoice
		client.priorityInvoice = invoice
		invoice.client = client
		@mockObjectStore.commit client
		@mockObjectStore.commit invoice
		data = Marshal.dump client
		clientPrime = Marshal.load data
		assert_equal client, clientPrime.priorityInvoice.client
	end

	def test_default_field_setup_hash
		assert_equal(
			BooleanField::ENUMS_CAPITAL_YES_NO,
			DomainObjChild1.get_field( 'bool1' ).enum_type
		)
		assert_equal(
			BooleanField::ENUMS_ONE_ZERO,
			DomainObjChild1.get_field( 'bool2' ).enum_type
		)
	end

	def test_defers_field_copying
		row_hash = OneTimeAccessHash.new( 'pk_id' => '1', 'hours' => '36.5',
		                                  'xmlSku' => nil )
		converter = SqlValueConverter.new( Invoice, row_hash )
		inv = Invoice.new( converter )
		assert_equal( 0, row_hash.key_lookups['pk_id'] )
		assert_equal( 0, row_hash.key_lookups['hours'] )
		assert_equal( 0, row_hash.key_lookups['xmlSku'] )
		assert_equal( 36.5, inv.hours )
		assert_equal( 1, row_hash.key_lookups['hours'] )
		assert_nil( inv.xmlSku )
		assert_equal( 1, row_hash.key_lookups['xmlSku'] )
		assert_nil( inv.xmlSku )
		assert_equal( 1, row_hash.key_lookups['xmlSku'] )
		xml_sku_row_hash = OneTimeAccessHash.new( 'some_other_id' => '345' )
		xml_sku_converter = SqlValueConverter.new( XmlSku, xml_sku_row_hash )
		xml_sku = XmlSku.new( xml_sku_converter )
		assert_equal( 345, xml_sku.pk_id )
	end
	
  def testDefinesSetters
    client = newTestClientWithoutPkId
    assert_equal("clientName", client.name)
    client.name = "newClientName"
    assert_equal("newClientName", client.name)
  end

	def test_dispatch_to_object_store
		invoice = Invoice.storedTestInvoice
		client = Client.storedTestClient
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
	
	def testDontSetDeleteWithoutPkId
		foo = Client.new( { "name" => "clientName1" } )
		begin
			foo.delete = 1
			fail "You can't delete something that hasn't been committed"
		rescue
			# fine
		end
	end

  def testDumpable
    client = newTestClientWithoutPkId
    data = Marshal.dump client
    newClient = Marshal.load data
    assert_equal Client, newClient.class
		assert_nil newClient.pk_id
		client2 = Client.getTestClient
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

	def testEquality
		client = Client.getTestClient
		clientPrime = Client.getTestClient
		assert_equal client, clientPrime
		assert( client.eql?( clientPrime ) )
		invoice = Invoice.getTestInvoice
		assert_equal 1, invoice.pk_id
		assert_equal 1, client.pk_id
		assert invoice != client
	end
	
	def test_fails_if_bad_hash
		assert_raise( ArgumentError ) {
			Client.new( 'not-a-field' => 'something' )
		}
	end

	def test_get_domain_class_from_string
		assert_equal(
			Class, DomainObject.get_domain_class_from_string( 'Invoice' ).class
		)
		assert_equal Class,(
				(DomainObject.get_domain_class_from_string('Domain::LineItem')).class)
		begin
			assert_equal(
				nil, ( DomainObject.get_domain_class_from_string( 'notADomainClass' ) )
			)
			fail "Should throw an error when matching fails"
		rescue CouldntMatchDomainClassError
			# ok
		end
		attributeClass = DomainObject.get_domain_class_from_string( 'Attribute' )
		assert_equal( Class, attributeClass.class )
		assert_equal( 'Attribute', attributeClass.to_s )
	end
	
	def test_get_domain_class_from_string_without_domain_file
		LafcadioConfig.set_filename '../test/testData/config_no_domain_file.dat'
		assert_equal( 'Invoice',
		              DomainObject.get_domain_class_from_string( 'Invoice' ).name )
	end

	def testGetField
		name = Client.get_class_field 'name'
		assert_not_nil name
		assert_equal( 'name', InternalClient.get_field( 'name' ).name )
		assert_equal( 'billingType', InternalClient.get_field( 'billingType' ).name )
		begin
			InternalClient.get_field( 'something' )
			fail "DomainObject.get_field needs to raise an error if it can't find " +
           "anything"
    rescue MissingError
    	# ok
    end
	end
	
	def testHandlesClassWithoutXml
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

	def testInheritance
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
	
	def testObjectLinksUpdateLive
		invoice = Invoice.storedTestInvoice
		client = Client.storedTestClient
		assert_equal client, invoice.client
		assert_equal client.name, invoice.client.name
		client.name = 'new name'
		@mockObjectStore.commit client
		assert_equal client.name, invoice.client.name
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
		assert_equal( 'xml_sku3_id', XmlSku3.get_field( 'pk_id' ).db_field_name )
	end

	def test_override_class_defaults_from_one_liners
		assert_equal( 'that_table', XmlSku2.table_name )
		assert_equal( 'xml_sku2_id', XmlSku2.sql_primary_key_name )
	end
	
	def testPkIdNeedsFixnum
		assert_equal Fixnum, Client.getTestClient.pk_id.class
	end

	def test_sql_primary_key_name
		assert_equal( DiffSqlPrimaryKey.sql_primary_key_name,
		              DiffSqlPrimaryKey.get_class_fields.first.db_field_name )
	end

	def testTableName
		assert_equal( "users", User.table_name )
		assert_equal( "line_items", Domain::LineItem.table_name )
	end
	
	def test_to_s
		assert_match( /Client/, newTestClientWithoutPkId.to_s )
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
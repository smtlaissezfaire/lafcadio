require 'lafcadio/test'
require 'lafcadio/domain'
require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Invoice'
require '../test/mock/domain/Client'
require '../test/mock/domain/User'
require '../test/mock/domain/XmlSku2'

class TestDomainObject < LafcadioTestCase
	def teardown
		super
		LafcadioConfig.setValues( nil )
	end

	def matchField( domainClass, fieldName, fieldClass, attributes = nil )
		field = domainClass.getClassField( fieldName )
		assert_not_nil( field )
		assert_equal( fieldClass, field.class )
		if attributes
			attributes.each { |attrName, attrValue|
				assert_equal( attrValue, field.send( attrName ) )
			}
		end
	end
	
	def newTestClientWithoutPkId
		Client.new( { "name" => "clientName" } )
	end

	def testAssignProxies
		invoice = Invoice.storedTestInvoice
		assert_equal 1, invoice.client.pkId
		client2 = Client.new({ 'pkId' => 2, 'name' => 'client 2' })
		invoice.client = client2
		client2Proxy = invoice.client
		assert_equal DomainObjectProxy, client2Proxy.class
		assert_equal 2, client2Proxy.pkId
		invoice.client = nil
		assert_nil invoice.client
	end

	def testCachesClassFields
		2.times { MockDomainObject.classFields }
	end

	def test_checks_fields_on_instantiation
		LafcadioConfig.setValues( 'checkFields' => 'onInstantiate' )
		assert_exception( FieldValueError, "Client#name should not be null." ) {
			Client.new( {} )
		}
	end
	
	def test_class_fields_from_one_line_class_methods
		matchField( XmlSku2, 'boolean1', BooleanField,
		            { 'enumType' => BooleanField::ENUMS_CAPITAL_YES_NO } )
		matchField( XmlSku2, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' },
		              'englishName' => 'boolean 2' } )
		matchField( XmlSku2, 'date1', DateField, { 'notNull' => false } )
		matchField( XmlSku2, 'date2', DateField,
		            { 'range' => DateField::RANGE_PAST } )
		matchField( XmlSku2, 'dateTime1', DateTimeField )
		matchField( XmlSku2, 'decimal1', DecimalField,
		            { 'englishName' => 'decimal 1' } )
		matchField( XmlSku2, 'email1', EmailField )
		matchField( XmlSku2, 'enum1', EnumField,
		            { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) } )
		matchField( XmlSku2, 'enum2', EnumField,
		            { 'enums' => QueueHash.new( '1', '2', '3', '4' ) } )
		matchField( XmlSku2, 'integer1', IntegerField )
		matchField( XmlSku2, 'link1', LinkField,
		            { 'linkedType' => User, 'deleteCascade' => true } )
		matchField( XmlSku2, 'money1', MoneyField )
		matchField( XmlSku2, 'month1', MonthField )
		matchField( XmlSku2, 'subsetLink1', SubsetLinkField,
		            { 'subsetField' => 'xmlSku' } )
		matchField( XmlSku2, 'text1', TextField,
		            { 'unique' => true } )
		matchField( XmlSku2, 'text2', TextField )
		matchField( XmlSku2, 'textList1', TextListField,
		            { 'dbFieldName' => 'text_list1' } )
		matchField( XmlSku2, 'timestamp1', TimeStampField )
	end
	
	def testClone
		client1 = newTestClientWithoutPkId
		client2 = client1.clone
		client2.name = 'client 2 name'
		assert_equal 'clientName', client1.name
	end
	
	def testCommit
		assert_equal 0, @mockObjectStore.getAll(Client).size
		client = newTestClientWithoutPkId
		something = client.commit
		assert_equal 1, @mockObjectStore.getAll(Client).size
		assert_equal( Client, something.class )
	end
	
	def testCreateWithLinkedProxies
		clientProxy = DomainObjectProxy.new Client, 99
		hash = { 'client' => clientProxy, 'rate' => 70,
				'date' => Date.new(2001, 4, 5), 'hours' => 36.5, 'invoice_num' => 1,
				'pkId' => 1 }
		invoice = Invoice.new hash
		proxyPrime = invoice.client
		assert_equal DomainObjectProxy, proxyPrime.class
		assert_equal Client, proxyPrime.objectType
		assert_equal 99, proxyPrime.pkId
		begin
			proxyPrime.name
			fail "should throw DomainObjectNotFoundError"
		rescue DomainObjectNotFoundError
			# ok
		end
		client = Client.getTestClient
    client.pkId = 99
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

	def test_defers_field_copying
		row_hash = OneTimeAccessHash.new( 'pkId' => '1', 'hours' => '36.5',
		                                  'xmlSku' => nil )
		converter = SqlValueConverter.new( Invoice, row_hash )
		inv = Invoice.new( converter )
		assert_equal( 1, row_hash.key_lookups['pkId'] )
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
		assert_equal( 345, xml_sku.pkId )
	end
	
  def testDefinesSetters
    client = newTestClientWithoutPkId
    assert_equal("clientName", client.name)
    client.name = "newClientName"
    assert_equal("newClientName", client.name)
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
		assert_nil newClient.pkId
		client2 = Client.getTestClient
		assert_equal 1, client2.pkId
		@mockObjectStore.commit client2
		data2 = Marshal.dump client2
		newClient2 = Marshal.load data2
		assert_equal 1, newClient2.pkId
		coll = [ client, client2 ]
		collData = Marshal.dump coll
		collPrime = Marshal.load collData
		assert_equal nil, collPrime[0].pkId
		assert_equal 1, collPrime[1].pkId
  end

	def testEquality
		client = Client.getTestClient
		clientPrime = Client.getTestClient
		assert_equal client, clientPrime
		assert( client.eql?( clientPrime ) )
		invoice = Invoice.getTestInvoice
		assert_equal 1, invoice.pkId
		assert_equal 1, client.pkId
		assert invoice != client
	end

	def testGetField
		name = Client.getClassField 'name'
		assert_not_nil name
		assert_equal( 'name', InternalClient.getField( 'name' ).name )
		assert_equal( 'billingType', InternalClient.getField( 'billingType' ).name )
		begin
			InternalClient.getField( 'something' )
			fail "DomainObject.getField needs to raise an error if it can't find " +
           "anything"
    rescue MissingError
    	# ok
    end
	end
	
	def testGetObjectTypeFromString
		assert_equal Class,((DomainObject.getObjectTypeFromString('Invoice')).class)
		assert_equal Class,(
				(DomainObject.getObjectTypeFromString('Domain::LineItem')).class)
		begin
			assert_equal nil,(DomainObject.getObjectTypeFromString('notAnObjectType'))
			fail "Should throw an error when matching fails"
		rescue CouldntMatchObjectTypeError
			# ok
		end
		attributeClass = DomainObject.getObjectTypeFromString( 'Attribute' )
		assert_equal( Class, attributeClass.class )
		assert_equal( 'Attribute', attributeClass.to_s )
	end
	
	def testGetObjectTypeFromStringWithoutDomainFile
		LafcadioConfig.setFilename '../test/testData/config_no_domain_file.dat'
		assert_equal( 'Invoice',
		              DomainObject.getObjectTypeFromString( 'Invoice' ).name )
	end
	
	def test_hash_and_eql
		client = Client.new( 'pkId' => 1, 'name' => 'client name' )
		client_prime = Client.new( 'pkId' => 1, 'name' => 'client name' )
		assert_equal( client.hash, client_prime.hash )
		assert( client.eql?( client_prime ) )
		assert( client_prime.eql?( client ) )
		client2 = Client.new( 'pkId' => 2, 'name' => 'someone else' )
		assert( !client.eql?( client2 ) )
	end
	
	def testInheritance
		ic = InternalClient.new({ 'name' => 'clientName1',
				'billingType' => 'trade' })
		assert_equal 'clientName1', ic.name
		assert_equal 'trade', ic.billingType
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

	def test_override_class_defaults_from_one_liners
		assert_equal( 'that_table', XmlSku2.tableName )
		assert_equal( 'xml_sku2_id', XmlSku2.sqlPrimaryKeyName )
	end
	
	def testPkIdNeedsFixnum
		assert_equal Fixnum, Client.getTestClient.pkId.class
	end

	def test_to_s
		assert_match( /Client/, newTestClientWithoutPkId.to_s )
	end

	class MockDomainObject < DomainObject
		@@classesInstantiated = false
		
		def MockDomainObject.getClassFields
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
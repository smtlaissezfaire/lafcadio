require 'lafcadio/test'
require 'lafcadio/domain'
require '../test/mock/domain'
require '../test/mock/domain/XmlSku'

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
		require '../test/mock/domain/User'
		matchField( XmlSku, 'boolean1', BooleanField,
		            { 'enum_type' => BooleanField::ENUMS_CAPITAL_YES_NO } )
		matchField( XmlSku, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' },
		              'english_name' => 'boolean 2' } )
		matchField( XmlSku, 'date1', DateField, { 'not_null' => false } )
		matchField( XmlSku, 'date2', DateField,
		            { 'range' => DateField::RANGE_PAST } )
		matchField( XmlSku, 'dateTime1', DateTimeField )
		matchField( XmlSku, 'decimal1', DecimalField,
		            { 'english_name' => 'decimal 1' } )
		matchField( XmlSku, 'email1', EmailField )
		matchField( XmlSku, 'enum1', EnumField,
		            { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) } )
		matchField( XmlSku, 'enum2', EnumField,
		            { 'enums' => QueueHash.new( '1', '2', '3', '4' ) } )
		matchField( XmlSku, 'integer1', IntegerField )
		matchField( XmlSku, 'link1', LinkField,
		            { 'linked_type' => User, 'delete_cascade' => true } )
		matchField( XmlSku, 'money1', MoneyField )
		matchField( XmlSku, 'month1', MonthField )
		matchField( XmlSku, 'subsetLink1', SubsetLinkField,
		            { 'subset_field' => 'xmlSku' } )
		matchField( XmlSku, 'text1', TextField, { 'unique' => true } )
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

	def testSetPkNameAndTableNameInXml
		assert_equal( 'some_other_id', XmlSku.sql_primary_key_name )
		assert_equal( 'pk_id', Attribute.sql_primary_key_name )
		assert_equal( 'some_other_table', XmlSku.table_name )
		assert_equal( 'attributes', Attribute.table_name )
	end
end
require 'lafcadio/test'
require 'lafcadio/domain'
require 'test/mock/domain/XmlSku'

class TestClassDefinitionXmlParser < LafcadioTestCase
	def execute( domainClass, xml )
		ClassDefinitionXmlParser.new( domainClass, xml ).execute
	end

	def matchField( domainClass, fieldName, fieldClass, attributes = nil )
		field = domainClass.getField( fieldName )
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
		require 'test/mock/domain/User'
		matchField( XmlSku, 'boolean1', BooleanField,
		            { 'enumType' => BooleanField::ENUMS_CAPITAL_YES_NO } )
		matchField( XmlSku, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' },
		              'englishName' => 'boolean 2' } )
		matchField( XmlSku, 'date1', DateField, { 'notNull' => false } )
		matchField( XmlSku, 'date2', DateField,
		            { 'range' => DateField::RANGE_PAST } )
		matchField( XmlSku, 'dateTime1', DateTimeField )
		matchField( XmlSku, 'decimal1', DecimalField,
		            { 'precision' => 4, 'englishName' => 'decimal 1' } )
		matchField( XmlSku, 'email1', EmailField )
		matchField( XmlSku, 'enum1', EnumField,
		            { 'enums' => QueueHash.new( 'a', 'a', 'b', 'b' ) } )
		matchField( XmlSku, 'enum2', EnumField,
		            { 'enums' => QueueHash.new( '1', '2', '3', '4' ) } )
		matchField( XmlSku, 'integer1', IntegerField )
		matchField( XmlSku, 'link1', LinkField, { 'linkedType' => User } )
		matchField( XmlSku, 'money1', MoneyField )
		matchField( XmlSku, 'month1', MonthField )
		matchField( XmlSku, 'subsetLink1', SubsetLinkField,
		            { 'subsetField' => 'xmlSku' } )
		matchField( XmlSku, 'text1', TextField, { 'size' => 16, 'unique' => true } )
		matchField( XmlSku, 'text2', TextField, { 'large' => true } )
		matchField( XmlSku, 'textList1', TextListField )
	end
	
	def testFieldNamesNeedToBeUnique
		begin
			execute( XmlSku, <<-XML
				<lafcadio_class_definition name="XmlSku">
					<field name="date1" class="DateField" notNull="n"/>
					<field name="date1" class="DateField"/>
				</lafcadio_class_definition>
			XML
			)
			raise "needs to throw an error if there are two names the same"
		rescue ClassDefinitionXmlParser::InvalidDataError
			# desired behavior
		end
	end
end
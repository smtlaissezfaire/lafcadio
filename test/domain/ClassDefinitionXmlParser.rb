require 'lafcadio/test'
require 'lafcadio/domain'

class TestClassDefinitionXmlParser < LafcadioTestCase
	class XmlSku < DomainObject
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
		matchField( XmlSku, 'boolean1', BooleanField,
		            { 'enumType' => BooleanField::ENUMS_CAPITAL_YES_NO } )
		matchField( XmlSku, 'boolean2', BooleanField,
		            { 'enums' => { true => 'yin', false => 'yang' } } )

		matchField( XmlSku, 'sku', TextField, { 'size' => 16, 'unique' => true } )
		matchField( XmlSku, 'standardPrice', MoneyField )
		matchField( XmlSku, 'description', TextField, { 'notNull' => false } )
		matchField( XmlSku, 'salePrice', MoneyField, { 'notNull' => false } )
		matchField( XmlSku, 'onSaleUntil', DateField, { 'notNull' => false } )
		matchField( XmlSku, 'size', TextField, { 'notNull' => false } )
	end
end
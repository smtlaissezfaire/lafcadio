require 'lafcadio/objectField'
require 'lafcadio/test'
require '../test/mock/domain'

class TestEnumField < LafcadioTestCase
	def TestEnumField.getTestEnumField
		cardTypes = QueueHash.new( 'AX', 'American Express', 'MC', 'MasterCard',
				'VI', 'Visa', 'DS', 'Discover' )
		EnumField.new User, "cardType", cardTypes,	"Credit card type"
	end

	def testSimpleEnumsArray
		field = EnumField.new User, "salutation", [ 'Mr', 'Mrs', 'Miss', 'Ms' ]
		enums = field.enums
		assert_equal 'Mr', enums['Mr']
	end
	
	def testValueForSql
		field = EnumField.new User, "salutation", [ 'Mr', 'Mrs', 'Miss', 'Ms' ]
		field.not_null = true
		assert_equal 'null', field.value_for_sql('')
	end
	
	def test_verify
		field = TestEnumField.getTestEnumField
		field.verify( 'AX', 1 )
		assert_raise( FieldValueError ) { field.verify( 'IOU', 1 ) }
		field.not_null = false
		field.verify( nil, 1 )
	end
end

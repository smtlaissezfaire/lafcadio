require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/cgi/FieldManager'
require 'lafcadio/objectField/BooleanField'
require 'lafcadio/mock/MockFieldManager'

class TestBooleanField < LafcadioTestCase
  def setup
  	super
    @bf = BooleanField.new(nil, "administrator")
    @bf.default = false
  end

	def testValueFromCGI
		fm = MockFieldManager.new {}
		field = BooleanField.new nil, "hidden"
		assert_equal false, field.valueFromCGI(fm)
	end

  def testDefault
    fm = MockFieldManager.new({})
    assert_equal(false, @bf.valueFromCGI(fm))
  end

  def testValueForSQL
    assert_equal("0", @bf.valueForSQL(false))
  end

	def testValueFromSQL
		assert_equal true, @bf.valueFromSQL('1')
		assert_equal false, @bf.valueFromSQL('0')
	end

	def testWithDifferentEnums
		bf2 = BooleanField.new nil, 'whatever'
		bf2.enumType = BooleanField::ENUMS_CAPITAL_YES_NO
		assert_equal("'N'", bf2.valueForSQL(false))
		assert_equal true, bf2.valueFromSQL('Y')
		assert_equal false, bf2.valueFromSQL('N')
		bf3 = BooleanField.new nil, 'whatever'
		bf3.enums =({ true => '', false => 'N' })
		assert_equal true, bf3.valueFromSQL('')
		assert_equal false, bf3.valueFromSQL('N')
	end
end
require 'lafcadio/test'
require 'lafcadio/objectField'

class TestBooleanField < LafcadioTestCase
  def setup
  	super
    @bf = BooleanField.new(nil, "administrator")
  end

  def testValueForSQL
    assert_equal(0, @bf.value_for_sql(false))
  end

	def testValueFromSQL
		assert_equal true, @bf.value_from_sql(1)
		assert_equal true, @bf.value_from_sql('1')
		assert_equal false, @bf.value_from_sql(0)
		assert_equal false, @bf.value_from_sql('0')
	end

	def testWithDifferentEnums
		bf2 = BooleanField.new nil, 'whatever'
		bf2.enum_type = BooleanField::ENUMS_CAPITAL_YES_NO
		assert_equal("'N'", bf2.value_for_sql(false))
		assert_equal true, bf2.value_from_sql('Y')
		assert_equal false, bf2.value_from_sql('N')
		bf3 = BooleanField.new nil, 'whatever'
		bf3.enums =({ true => '', false => 'N' })
		assert_equal true, bf3.value_from_sql('')
		assert_equal false, bf3.value_from_sql('N')
	end
	
	def test_raise_error_if_no_enums_available
		@bf.enum_type = 999
		begin
			@bf.get_enums
			fail "should raise MissingError"
		rescue MissingError
			# ok
		end
	end
	
	def test_text_enums
		@bf.enums = { true => '1', false => '0' }
		assert_equal( "'1'", @bf.value_for_sql( true ) )
		assert_equal( "'0'", @bf.value_for_sql( false ) )
	end
end
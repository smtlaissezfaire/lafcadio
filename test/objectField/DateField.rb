require 'dbi'
require 'lafcadio/objectField'
require 'lafcadio/test'
require '../test/mock/domain'

class TestDateField < LafcadioTestCase
  def setup
  	super
    @odf = DateField.new Invoice
  end

  def testValueForSQL
    assert_equal("'2001-04-05'", @odf.value_for_sql(Date.new(2001, 4, 5)))
		assert_equal 'null', @odf.value_for_sql(nil)
  end

  def testNotNull
    odf1 = DateField.new nil
    assert(odf1.not_null)
    odf1.not_null = false
    assert(!odf1.not_null)
  end

  def testCatchesBadFormat
    begin
      @odf.verify("2001-04-05", nil)
      fail "Should raise an error with a bad value"
    rescue
			# ok
    end
    @odf.verify(Date.new(2001, 4, 5), nil)
  end

  def testValueFromSQL
		obj = @odf.value_from_sql( DBI::Date.new( 2001, 4, 5 ) )
    assert_equal(Date, obj.class)
		obj2 = @odf.value_from_sql( DBI::Date.new( 0, 0, 0 ) )
    assert_nil obj2
		obj3 = @odf.value_from_sql nil
		assert_nil obj3
  end
end
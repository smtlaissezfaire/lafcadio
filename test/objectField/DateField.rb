require 'dbi'
require 'lafcadio/objectField/DateField'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Invoice'
require 'lafcadio/objectField/FieldValueError'
require 'lafcadio/mock/MockFieldManager'

class TestDateField < LafcadioTestCase
  def setup
  	super
    @odf = DateField.new Invoice
  end

  def testValueForSQL
    assert_equal("'2001-04-05'", @odf.valueForSQL(Date.new(2001, 4, 5)))
		assert_equal 'null', @odf.valueForSQL(nil)
  end

  def testNotNull
    odf1 = DateField.new nil
    assert(odf1.notNull)
    odf1.notNull = false
    assert(!odf1.notNull)
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
		obj = @odf.valueFromSQL( DBI::Date.new( 2001, 4, 5 ) )
    assert_equal(Date, obj.class)
		obj2 = @odf.valueFromSQL( DBI::Date.new( 0, 0, 0 ) )
    assert_nil obj2
		obj3 = @odf.valueFromSQL nil
		assert_nil obj3
  end

  def testValueFromCGI
    fm = MockFieldManager.new( { "date.year" => "2001", "date.month" => "1",
				  "date.dom" => "30" } )
    assert_equal(Date.new(2001, 1, 30), @odf.valueFromCGI(fm))
  end
end
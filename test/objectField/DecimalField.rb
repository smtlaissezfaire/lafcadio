require 'lafcadio/test'
require '../test/mock/domain'

class TestDecimalField < LafcadioTestCase
  def setup
  	super
    @odf = DecimalField.new(Invoice, "hours", 2)
  end
  
  def testGetvalue_from_sql
    obj = @odf.value_from_sql "1.1"
    assert_equal(1.1, obj)    
  end

	def testValueForSQL
		assert_equal 'null', @odf.value_for_sql(nil)
	end

  def testNeedsNumeric
    caught = false
    begin
      @odf.verify("36.5", nil)
    rescue
      caught = true
    end
    assert(caught)
    @odf.verify(36.5, nil)
  end
end

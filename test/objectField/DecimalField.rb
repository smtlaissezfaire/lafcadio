require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Invoice'

class TestDecimalField < LafcadioTestCase
  def setup
  	super
    @odf = DecimalField.new(Invoice, "hours", 2)
  end
  
  def testGetvalueFromSQL
    obj = @odf.valueFromSQL "1.1"
    assert_equal(1.1, obj)    
  end

	def testValueForSQL
		assert_equal 'null', @odf.valueForSQL(nil)
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

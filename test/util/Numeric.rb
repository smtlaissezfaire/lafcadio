require 'lafcadio/util'
require 'runit/testcase'

class TestNumeric < RUNIT::TestCase
  def testPrecisionFormat
    assert_equal("24.550", 24.55.precision_format(3))
    assert_equal("24.5", 24.55.precision_format(1))
    assert_equal("24", 24.55.precision_format(0))
    assert_equal("96.00", 96.precision_format(2))
  end

  def testPrecisionFormatWithoutDecimalPadding
  	assert_equal '100.00',(100.precision_format(2))
  	assert_equal '100',(100.precision_format(2, false))
  	assert_equal '99.95',(99.95.precision_format(2))
  	assert_equal '99.95',(99.95.precision_format(2, false))
  end
end
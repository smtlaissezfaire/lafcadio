require 'runit/testcase'
require 'lafcadio/util/StrUtil'

class TestStrUtil < RUNIT::TestCase
  def testFloatFormat
    assert_equal("24.550", StrUtil.floatFormat(24.55, 3))
    assert_equal("24.5", StrUtil.floatFormat(24.55, 1))
    assert_equal("24", StrUtil.floatFormat(24.55, 0))
    assert_equal("96.00", StrUtil.floatFormat(96, 2))
  end
  
  def testFloatFormatWithoutDecimalPadding
  	assert_equal '100.00', StrUtil.floatFormat (100, 2)
  	assert_equal '100', StrUtil.floatFormat (100, 2, false)
  	assert_equal '99.95', StrUtil.floatFormat (99.95, 2)
  	assert_equal '99.95', StrUtil.floatFormat (99.95, 2, false)
  end

  def testIncrementsFilename
    assert_equal "john_1.jpg", StrUtil.incrementFilename("john.jpg")
    assert_equal "john_2.jpg", StrUtil.incrementFilename("john_1.jpg")
    assert_equal "john_3.jpg", StrUtil.incrementFilename("john_2.jpg")
  end

	def testDecapitalize
		assert_equal 'internalClient', StrUtil.decapitalize('InternalClient')
		assert_equal 'order', StrUtil.decapitalize('Order')
		assert_equal 'sku', StrUtil.decapitalize('SKU')
	end

	def testCountOccurrences
		assert_equal 0, StrUtil.countOccurrences('abcd', /e/)
		assert_equal 1, StrUtil.countOccurrences('abcd', /a/)
		assert_equal 2, StrUtil.countOccurrences('aabaabababa', /aab/)
		assert_equal 1, StrUtil.countOccurrences("ab\ncd", /b(\s*)c/)
		assert_equal 2, StrUtil.countOccurrences('aabaabababa', /a
			ab/x)
	end

	def testNumericStringToUsFormat
		assert_equal '5.00', StrUtil.numericStringToUsFormat ('5,00')
		assert_equal '5,000', StrUtil.numericStringToUsFormat ('5,000')
	end

	def testSplitKeepInbetweens
		result = StrUtil.splitKeepInBetweens('the quick  brown fox', /\s+/)
		assert_equal ['the', ' ', 'quick', '  ', 'brown', ' ', 'fox' ], result
	end
end
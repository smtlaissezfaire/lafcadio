require 'lafcadio/util'
require 'runit/testcase'

class TestString < RUNIT::TestCase
  def testIncrementsFilename
    assert_equal "john_1.jpg", ("john.jpg".incrementFilename)
    assert_equal "john_2.jpg", ("john_1.jpg".incrementFilename)
    assert_equal "john_3.jpg", ("john_2.jpg".incrementFilename)
  end

	def testDecapitalize
		assert_equal 'internalClient', ('InternalClient'.decapitalize)
		assert_equal 'order', ('Order'.decapitalize)
		assert_equal 'sku', ('SKU'.decapitalize)
	end

	def testCountOccurrences
		assert_equal 0, 'abcd'.countOccurrences(/e/)
		assert_equal 1, 'abcd'.countOccurrences(/a/)
		assert_equal 2, 'aabaabababa'.countOccurrences(/aab/)
		assert_equal 1, "ab\ncd".countOccurrences(/b(\s*)c/)
		assert_equal 2, 'aabaabababa'.countOccurrences(/a
			ab/x)
	end

	def testNumericStringToUsFormat
		assert_equal '5.00',('5,00'.numericStringToUsFormat)
		assert_equal '5,000',('5,000'.numericStringToUsFormat)
	end

	def testSplitKeepInbetweens
		result = 'the quick  brown fox'.splitKeepInBetweens(/\s+/)
		assert_equal ['the', ' ', 'quick', '  ', 'brown', ' ', 'fox' ], result
	end

	def testLineWrap
		qbr = 'the quick brown fox jumped over the lazy dog.'
		result = qbr.lineWrap(10)
		assert_equal "the quick\nbrown fox\njumped\nover the\nlazy dog.", result
	end
end
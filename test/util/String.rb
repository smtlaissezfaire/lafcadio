require 'lafcadio/util'
require 'test/unit'

class TestString < Test::Unit::TestCase
  def testIncrementsFilename
    assert_equal "john_1.jpg", ("john.jpg".increment_filename)
    assert_equal "john_2.jpg", ("john_1.jpg".increment_filename)
    assert_equal "john_3.jpg", ("john_2.jpg".increment_filename)
  end

	def testDecapitalize
		assert_equal 'internalClient', ('InternalClient'.decapitalize)
		assert_equal 'order', ('Order'.decapitalize)
		assert_equal 'sku', ('SKU'.decapitalize)
	end

	def testCountOccurrences
		assert_equal 0, 'abcd'.count_occurrences(/e/)
		assert_equal 1, 'abcd'.count_occurrences(/a/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/aab/)
		assert_equal 1, "ab\ncd".count_occurrences(/b(\s*)c/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/a
			ab/x)
	end

	def testNumericStringToUsFormat
		assert_equal '5.00',('5,00'.numeric_string_to_us_format)
		assert_equal '5,000',('5,000'.numeric_string_to_us_format)
	end

	def testSplitKeepInbetweens
		result = 'the quick  brown fox'.split_keep_in_betweens(/\s+/)
		assert_equal ['the', ' ', 'quick', '  ', 'brown', ' ', 'fox' ], result
	end

	def testLineWrap
		qbr = 'the quick brown fox jumped over the lazy dog.'
		result = qbr.line_wrape(10)
		assert_equal "the quick\nbrown fox\njumped\nover the\nlazy dog.", result
	end

	def test_underscore_to_camel_case
		assert_equal( 'ObjectStore', 'object_store'.underscore_to_camel_case )
	end
	
	def test_camel_case_to_underscore
		assert_equal( 'object_store', 'ObjectStore'.camel_case_to_underscore )
	end
end
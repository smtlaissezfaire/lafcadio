require 'test/unit'
require 'lafcadio/test'
require 'lafcadio/util'
require 'lafcadio/mock'

class TestConfig < Test::Unit::TestCase
	include Lafcadio

	def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
		@config = LafcadioConfig.new
	end
	
	def teardown
		LafcadioConfig.set_values( nil )
	end
	
	def test_empty_ok
		LafcadioConfig.set_values nil
		LafcadioConfig.set_filename nil
		lc = LafcadioConfig.new
	end

	def test_define_in_code
		LafcadioConfig.set_filename( nil )
		LafcadioConfig.set_values(
			'dbuser' => 'test', 'dbhost' => 'localhost',
		  'domainDirs' => [ 'lafcadio/domain/', '../test/mock/domain/' ]
		)
		config = LafcadioConfig.new
		assert_equal( 'test', config['dbuser'] )
		assert_equal( 'localhost', config['dbhost'] )
		assert( config['domainDirs'].include?( 'lafcadio/domain/' ) )
		LafcadioConfig.set_values( 'domainFiles' => %w( ../test/mock/domain ) )
		DomainObject.require_domain_file( 'User' )
	end
end

class TestString < Test::Unit::TestCase
	def test_camel_case_to_underscore
		assert_equal( 'object_store', 'ObjectStore'.camel_case_to_underscore )
	end

	def testCountOccurrences
		assert_equal 0, 'abcd'.count_occurrences(/e/)
		assert_equal 1, 'abcd'.count_occurrences(/a/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/aab/)
		assert_equal 1, "ab\ncd".count_occurrences(/b(\s*)c/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/a
			ab/x)
	end

	def testDecapitalize
		assert_equal 'internalClient', ('InternalClient'.decapitalize)
		assert_equal 'order', ('Order'.decapitalize)
		assert_equal 'sku', ('SKU'.decapitalize)
	end

	def test_underscore_to_camel_case
		assert_equal( 'ObjectStore', 'object_store'.underscore_to_camel_case )
	end
end
require 'test/unit'
require 'lafcadio/test'
require 'lafcadio/util'
require 'lafcadio/mock'

class TestLafcadioConfig < Test::Unit::TestCase
	include Lafcadio

	def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
		@config = LafcadioConfig.new
	end
	
	def teardown
		LafcadioConfig.set_values( nil )
	end

	def test_define_in_code
		LafcadioConfig.set_filename( nil )
		LafcadioConfig.set_values(
			'dbuser' => 'test', 'dbhost' => 'localhost',
		  'domainDirs' => [ 'lafcadio/domain/', '../test/mock_domain/' ]
		)
		config = LafcadioConfig.new
		assert_equal( 'test', config['dbuser'] )
		assert_equal( 'localhost', config['dbhost'] )
		assert( config['domainDirs'].include?( 'lafcadio/domain/' ) )
		LafcadioConfig.set_values( 'domainFiles' => %w( ../test/mock_domain ) )
		DomainObject.require_domain_file( 'User' )
	end
	
	def test_empty_ok
		LafcadioConfig.set_values nil
		LafcadioConfig.set_filename nil
		lc = LafcadioConfig.new
	end
	
	def test_set_value
		lc = LafcadioConfig.new
		assert_equal( 'localhost', lc['dbhost'] )
		host2 = 'some.other.server.com'
		LafcadioConfig['dbhost'] = host2
		assert_equal( host2, lc['dbhost'] )
		assert_equal( host2, LafcadioConfig.new['dbhost'] )
	end
end

class TestString < Test::Unit::TestCase
	def test_camel_case_to_underscore
		assert_equal( 'object_store', 'ObjectStore'.camel_case_to_underscore )
	end

	def test_underscore_to_camel_case
		assert_equal( 'ObjectStore', 'object_store'.underscore_to_camel_case )
	end
end
require 'lafcadio/util'
require 'runit/testcase'

class TestConfig < RUNIT::TestCase
	include Lafcadio

	def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
		@config = LafcadioConfig.new
	end

	def testURL
		assert_equal "http://test.url", @config['url']
	end

	def testSiteName
		assert_equal 'Site Name', @config['siteName']
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
	end
end

require 'lafcadio/util/LafcadioConfig'
require 'runit/testcase'

class TestConfig < RUNIT::TestCase
	include Lafcadio

	def setup
		LafcadioConfig.setFilename 'lafcadio/test/testconfig.dat'
		@config = LafcadioConfig.new
	end

	def testURL
		assert_equal "http://test.url", @config['url']
	end

	def testSiteName
		assert_equal 'Site Name', @config['siteName']
	end
	
	def test_define_in_code
		LafcadioConfig.setFilename( nil )
		LafcadioConfig.setValues(
			'dbuser' => 'test', 'dbhost' => 'localhost',
		  'domainDirs' => [ 'lafcadio/domain/', '../test/mock/domain/' ]
		)
		config = LafcadioConfig.new
		assert_equal( 'test', config['dbuser'] )
		assert_equal( 'localhost', config['dbhost'] )
		assert( config['domainDirs'].include?( 'lafcadio/domain/' ) )
	end
end

require 'lafcadio/util/Config'
require 'runit/testcase'

class TestConfig < RUNIT::TestCase
	def setup
		Config.setFilename 'lafcadio/testconfig.dat'
		@config = Config.new
	end

	def testURL
		assert_equal "http://test.url", @config['url']
	end

	def testSiteName
		assert_equal 'Site Name', @config['siteName']
	end
end

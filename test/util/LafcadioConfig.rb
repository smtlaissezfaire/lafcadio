require 'lafcadio/util/LafcadioConfig'
require 'runit/testcase'

class TestConfig < RUNIT::TestCase
	include Lafcadio

	def setup
		LafcadioConfig.setFilename 'lafcadio/testconfig.dat'
		@config = LafcadioConfig.new
	end

	def testURL
		assert_equal "http://test.url", @config['url']
	end

	def testSiteName
		assert_equal 'Site Name', @config['siteName']
	end
end

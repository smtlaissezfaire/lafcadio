require 'runit/testcase'
require 'lafcadio/mock/MockObjectStore'
require 'lafcadio/mock/MockEmailer'
require 'lafcadio/util/LafcadioConfig'

class LafcadioTestCase < RUNIT::TestCase
  def setup
  	context = Context.instance
  	context.flush
    @mockObjectStore = MockObjectStore.new context
		context.setObjectStore @mockObjectStore
		@mockEmailer = MockEmailer.new
		context.setEmailer @mockEmailer
		LafcadioConfig.setFilename 'lafcadio/testConfig.dat'
  end
end

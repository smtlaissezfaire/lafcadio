require 'runit/testcase'
require 'lafcadio/mock/MockObjectStore'
require 'lafcadio/mock/MockEmailer'
require 'lafcadio/util/Config'

class LafcadioTestCase < RUNIT::TestCase
  def setup
  	context = Context.instance
  	context.flush
    @mockObjectStore = MockObjectStore.new context
		context.setObjectStore @mockObjectStore
		@mockEmailer = MockEmailer.new
		context.setEmailer @mockEmailer
		Config.setFilename 'lafcadio/testconfig.dat'
  end
end

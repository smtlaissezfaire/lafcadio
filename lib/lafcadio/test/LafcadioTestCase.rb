require 'runit/testcase'
require 'lafcadio/mock/MockObjectStore'
require 'lafcadio/util/LafcadioConfig'

# A test case that sets up a number of mock services. In writing an application 
# that uses Lafcadio you may find it convenient to inherit from this class.
class LafcadioTestCase < RUNIT::TestCase
	include Lafcadio

  def setup
  	context = Context.instance
  	context.flush
    @mockObjectStore = MockObjectStore.new context
		context.setObjectStore @mockObjectStore
		LafcadioConfig.setFilename 'lafcadio/test/testConfig.dat'
  end
end

require 'runit/testcase'
require 'lafcadio/util/Context'
require 'lafcadio/mock/MockObjectStore'
require 'lafcadio/util/LafcadioConfig'

class TestContext < RUNIT::TestCase
	include Lafcadio

	def setup
		Context.instance.flush
	end

	def testSingleton
		assert_equal Context.instance.id, Context.instance.id
	end
	
	def testSetterAndGetter
		context1 = Context.instance
		context2 = Context.instance
		mockObjectStore = MockObjectStore.new context1
		context1.setObjectStore mockObjectStore
		assert_equal mockObjectStore, context2.getObjectStore
	end
	
	def testCreatesStandardInstances
		LafcadioConfig.setFilename 'lafcadio/testconfig.dat'
		objectStore = Context.instance.getObjectStore
		assert_equal ObjectStore, objectStore.class
	end
end
require 'test/unit'
require 'lafcadio/util'
require 'lafcadio/mock'

class TestContext < Test::Unit::TestCase
	include Lafcadio

	def setup
		Context.instance.flush
	end

	def testSingleton
		assert_equal Context.instance.object_id, Context.instance.object_id
	end
	
	def testSetterAndGetter
		context1 = Context.instance
		context2 = Context.instance
		context1.set_init_proc( ObjectStore, proc { MockObjectStore.new } )
		mockObjectStore = context1.get_resource( ObjectStore )
		assert_equal mockObjectStore, context2.get_resource( ObjectStore )
	end
	
	def testCreatesStandardInstances
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
		objectStore = ObjectStore.get_object_store
		assert_equal ObjectStore, objectStore.class
	end
end
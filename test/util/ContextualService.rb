require 'runit/testcase'
require 'lafcadio/util/Context'
require 'lafcadio/util/ContextualService'

class TestContextualService < RUNIT::TestCase
	class ServiceA < ContextualService
	end
	
	class ServiceB < ContextualService
	end
	
	def testClassMethodAccess
		context = Context.instance
		serviceA = ServiceA.new context
		context.setServiceA serviceA
		assert_equal serviceA, context.getServiceA
		assert_equal serviceA, ServiceA.getServiceA
		serviceB = ServiceB.new context
		context.setServiceB serviceB
		assert_equal serviceB, ServiceB.getServiceB
		assert ServiceA.getServiceA != ServiceB.getServiceB
	end
end
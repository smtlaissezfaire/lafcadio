require 'runit/testcase'
require 'lafcadio/util'

class TestContextualService < RUNIT::TestCase
	include Lafcadio

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
	
	class Outer; class Inner < Lafcadio::ContextualService; end; end
	
	def test_handles_inner_class_child
		inner = Outer::Inner.getInner
		assert_equal( Outer::Inner, inner.class )
		inner_prime = Outer::Inner.getInner
		assert_equal( inner, inner_prime )
	end
end
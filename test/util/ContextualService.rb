require 'runit/testcase'
require 'lafcadio/util'

include Lafcadio
class ServiceA < ContextualService
end

class ServiceB < ContextualService
end
	
class TestContextualService < RUNIT::TestCase
	def testClassMethodAccess
		context = Context.instance
		serviceA = ServiceA.new context
		context.setServiceA serviceA
		assert_equal serviceA, context.get_service_a
		assert_equal serviceA, ServiceA.get_service_a
		serviceB = ServiceB.new context
		context.setServiceB serviceB
		assert_equal serviceB, ServiceB.get_service_b
		assert ServiceA.get_service_a != ServiceB.get_service_b
	end
	
	class Outer; class Inner < Lafcadio::ContextualService; end; end
	
	def test_handles_inner_class_child
		inner = Outer::Inner.get_inner
		assert_equal( Outer::Inner, inner.class )
		inner_prime = Outer::Inner.get_inner
		assert_equal( inner, inner_prime )
	end
end
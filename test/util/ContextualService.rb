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
		serviceA = ServiceA.get_service_a
		context.set_service_a serviceA
		assert_equal serviceA, context.get_service_a
		assert_equal serviceA, ServiceA.get_service_a
		serviceB = ServiceB.get_service_b
		context.set_service_b serviceB
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
	
	def test_requires_init_called_through_Context_create_instance
		context = Context.instance
		assert_exception( ArgumentError ) { ServiceA.new }
		assert_equal( ServiceA, ServiceA.get_service_a.class )
	end
	
	def test_set_init_proc
		Context.instance.flush
		ServiceA.set_init_proc { Array.new }
		mock_service_a = ServiceA.get_service_a
		assert_equal( Array, mock_service_a.class )
		mock_service_a_prime = ServiceA.get_service_a
		assert_equal( mock_service_a.id, mock_service_a_prime.id )
	end
end
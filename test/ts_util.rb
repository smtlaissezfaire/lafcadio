require 'test/unit'
require 'lafcadio/test'
require 'lafcadio/util'
require 'lafcadio/mock'

class TestContext < Test::Unit::TestCase
	include Lafcadio

	def setup
		Context.instance.flush
	end

	def testCreatesStandardInstances
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
		objectStore = ObjectStore.get_object_store
		assert_equal ObjectStore, objectStore.class
	end

	def testSetterAndGetter
		context1 = Context.instance
		context2 = Context.instance
		context1.set_init_proc( ObjectStore, proc { MockObjectStore.new } )
		mockObjectStore = context1.get_resource( ObjectStore )
		assert_equal mockObjectStore, context2.get_resource( ObjectStore )
	end

	def testSingleton
		assert_equal Context.instance.object_id, Context.instance.object_id
	end
end

include Lafcadio
class ServiceA < ContextualService
end

class ServiceB < ContextualService
end

class ParamService < ContextualService
	def initialize( arg1, arg2 )
		super()
	end
end
	
class TestContextualService < Test::Unit::TestCase
	def testClassMethodAccess
		context = Context.instance
		serviceA = ServiceA.get_service_a
		ServiceA.set_service_a serviceA
		assert_equal serviceA, context.get_resource( ServiceA )
		assert_equal serviceA, ServiceA.get_service_a
		serviceB = ServiceB.get_service_b
		context.set_resource( ServiceB, serviceB )
		assert_equal serviceB, ServiceB.get_service_b
		assert ServiceA.get_service_a != ServiceB.get_service_b
		assert_raise( NoMethodError ) { context.setServiceA }
		assert_raise( NoMethodError ) { context.getServiceA }
	end
	
	def test_flush
		service_a = ServiceA.get_service_a
		ServiceA.flush
		assert( service_a != ServiceA.get_service_a )
	end
	
	def test_garbage
		assert_raise( NoMethodError ) { ObjectStore.get_something_or_other }
		assert_raise( NoMethodError ) { ObjectStore.get_service_a }
		assert_raise( NoMethodError ) { ObjectStore.set_something_or_other( 999 ) }
		assert_raise( NoMethodError ) { ObjectStore.set_service_b }
	end

	def test_handles_inner_class_child
		inner = Outer::Inner.get_inner
		assert_equal( Outer::Inner, inner.class )
		inner_prime = Outer::Inner.get_inner
		assert_equal( inner, inner_prime )
	end
	
	def test_init_with_args
		serv1 = ParamService.get_param_service( 123, 456 )
		serv2 = ParamService.get_param_service( 123, 456 )
		assert_equal( serv1.id, serv2.id )
		serv3 = ParamService.get_param_service( 456, 123 )
		assert( serv1.id != serv3.id )
		mock_serv = "some object"
		ParamService.set_param_service( mock_serv, 111, 222 )
		assert_equal( mock_serv, ParamService.get_param_service( 111, 222 ) )
	end
	
	def test_requires_init_called_through_Context_create_instance
		context = Context.instance
		assert_raise( ArgumentError ) { ServiceA.new }
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

	class Outer; class Inner < Lafcadio::ContextualService; end; end
end

class TestConfig < Test::Unit::TestCase
	include Lafcadio

	def setup
		LafcadioConfig.set_filename 'lafcadio/test/testconfig.dat'
		@config = LafcadioConfig.new
	end
	
	def teardown
		LafcadioConfig.set_values( nil )
	end

	def test_define_in_code
		LafcadioConfig.set_filename( nil )
		LafcadioConfig.set_values(
			'dbuser' => 'test', 'dbhost' => 'localhost',
		  'domainDirs' => [ 'lafcadio/domain/', '../test/mock/domain/' ]
		)
		config = LafcadioConfig.new
		assert_equal( 'test', config['dbuser'] )
		assert_equal( 'localhost', config['dbhost'] )
		assert( config['domainDirs'].include?( 'lafcadio/domain/' ) )
		LafcadioConfig.set_values( 'domainFiles' => %w( ../test/mock/domain ) )
		DomainObject.require_domain_file( 'User' )
	end
end

class TestString < Test::Unit::TestCase
	def test_camel_case_to_underscore
		assert_equal( 'object_store', 'ObjectStore'.camel_case_to_underscore )
	end

	def testCountOccurrences
		assert_equal 0, 'abcd'.count_occurrences(/e/)
		assert_equal 1, 'abcd'.count_occurrences(/a/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/aab/)
		assert_equal 1, "ab\ncd".count_occurrences(/b(\s*)c/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/a
			ab/x)
	end

	def testDecapitalize
		assert_equal 'internalClient', ('InternalClient'.decapitalize)
		assert_equal 'order', ('Order'.decapitalize)
		assert_equal 'sku', ('SKU'.decapitalize)
	end

	def test_underscore_to_camel_case
		assert_equal( 'ObjectStore', 'object_store'.underscore_to_camel_case )
	end
end
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

include Lafcadio
class ServiceA < ContextualService
end

class ServiceB < ContextualService
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
	
	class Outer; class Inner < Lafcadio::ContextualService; end; end
	
	def test_handles_inner_class_child
		inner = Outer::Inner.get_inner
		assert_equal( Outer::Inner, inner.class )
		inner_prime = Outer::Inner.get_inner
		assert_equal( inner, inner_prime )
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
end

class TestEnglish < LafcadioTestCase
  def testCamelCaseToEnglish
    assert_equal "product category",
				English.camel_case_to_english("productCategory")
		assert_equal "product category",
				English.camel_case_to_english("ProductCategory")
		assert_equal 'catalog order',
				English.camel_case_to_english('catalogOrder')
		assert_equal 'product', English.camel_case_to_english('product')
  end

  def testSentence
    sentence = English.sentence("There %is currently %num %nam",
				"product category", 0)
    assert_equal("There are currently 0 product categories", sentence)
		sentence2 = English.sentence("Add %a %nam", "sku")
		assert_equal("Add a sku", sentence2)
		sentence3 = English.sentence("Add %a %nam", "invoice")
		assert_equal("Add an invoice", sentence3)
		sentence4 = English.sentence("Add %a %nam", 'user')
		assert_equal 'Add a user', sentence4
  end

  def testPlural
    assert_equal "product categories", English.plural("product category")
    assert_equal "products", English.plural("product")
		assert_equal 'addresses', English.plural('address')
		assert_equal 'taxes', English.plural('tax')
  end

	def testProperNoun
		assert_equal "Albania", English.proper_noun("albania")
		assert_equal "Bosnia and Herzegovina",
				English.proper_noun("bosnia and herzegovina")
		assert_equal "Faroe Islands", English.proper_noun("faroe islands")
		assert_equal "Macedonia, the Former Yugoslav Republic of",
				English.proper_noun("macedonia, the former yugoslav republic of")
		assert_equal "Virgin Islands, U.S.",
				English.proper_noun("virgin islands, u.s.")
	end

	def testStartsWithVowelSound
		assert English.starts_with_vowel_sound('order')
		assert !English.starts_with_vowel_sound('catalogOrder')
		assert !English.starts_with_vowel_sound('user')
	end

	def testSingular
		assert_equal 'tree', English.singular('trees')
		assert_equal 'fairy', English.singular('fairies')
		assert_equal 'address', English.singular('addresses')
	end
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

	def testURL
		assert_equal "http://test.url", @config['url']
	end

	def testSiteName
		assert_equal 'Site Name', @config['siteName']
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
	end
end

class TestQueueHash < LafcadioTestCase
  def setup
    @qh = QueueHash.new("q", "w", "e", "r", "t", "y")
  end

  def testKeyValue
    assert_equal("w", @qh["q"])
    assert_equal("r", @qh["e"])
    assert_equal("y", @qh["t"])
  end

  def testOrder
    assert_equal("q", @qh.keys[0])
    assert_equal("e", @qh.keys[1])
    assert_equal("t", @qh.keys[2])
  end

  def testSize
    assert_equal(3, @qh.size)
  end

  def testValues
    values = @qh.values
    assert_equal("w", values[0])
    assert_equal("r", values[1])
    assert_equal("y", values[2])
  end

  def testAssign
    qh = QueueHash.new
    qh["a"] = 1
    qh["b"] = 2
    qh["c"] = 3
    assert_equal(1, qh["a"])
    assert_equal(1, qh.values[0])
  end

	def testNewFromArray
		qh = QueueHash.new_from_array([ 'a', 'b', 'c' ])
		assert_equal 'a', qh['a']
		assert_equal 'b', qh['b']
		assert_equal 'c', qh['c']
	end

	def testIterate
		str = ""
		@qh.each { |name, value| str += name + value }
		assert_equal 'qwerty', str
	end
	
	def testEquality
		qhPrime = QueueHash.new("q", "w", "e", "r", "t", "y")
		assert_equal( @qh, qhPrime )
		anotherQh = QueueHash.new( 'a', 's', 'd', 'f', 'g', 'h' )
		assert( @qh != anotherQh )
	end
	
	def test_nil; assert_nil( @qh['qwerty'] ); end
end

class TestString < Test::Unit::TestCase
	def testDecapitalize
		assert_equal 'internalClient', ('InternalClient'.decapitalize)
		assert_equal 'order', ('Order'.decapitalize)
		assert_equal 'sku', ('SKU'.decapitalize)
	end

	def testCountOccurrences
		assert_equal 0, 'abcd'.count_occurrences(/e/)
		assert_equal 1, 'abcd'.count_occurrences(/a/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/aab/)
		assert_equal 1, "ab\ncd".count_occurrences(/b(\s*)c/)
		assert_equal 2, 'aabaabababa'.count_occurrences(/a
			ab/x)
	end

	def testNumericStringToUsFormat
		assert_equal '5.00',('5,00'.numeric_string_to_us_format)
		assert_equal '5,000',('5,000'.numeric_string_to_us_format)
	end

	def test_underscore_to_camel_case
		assert_equal( 'ObjectStore', 'object_store'.underscore_to_camel_case )
	end
	
	def test_camel_case_to_underscore
		assert_equal( 'object_store', 'ObjectStore'.camel_case_to_underscore )
	end
end
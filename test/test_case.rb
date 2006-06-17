require 'test/unit'

# A test case that sets up a number of mock services. In writing an application 
# that uses Lafcadio you may find it convenient to inherit from this class.
class LafcadioTestCase < Test::Unit::TestCase
	include Lafcadio

  def setup
  	context = ContextualService::Context.instance
  	context.flush
    @mockObjectStore = MockObjectStore.new
		ObjectStore.set_object_store @mockObjectStore
		LafcadioConfig.set_values(
			'classDefinitionDir' => '../test/testData', 'dbhost' => 'localhost',
			'dbname' => 'test', 'dbpassword' => 'password', 'dbuser' => 'test',
			'domainFiles' => %w( ../test/mock/domain ),
			'logdir' => '../test/testOutput/', 'logSql' => 'n'
		)
  end
	
	# Asserts that for each key-value pair in +att_values+, sending the key to
	# +object+ will return the value.
	#   u = User.new( 'fname' => 'Francis', 'lname' => 'Hwang' )
	#   assert_attributes( u, { 'fname' => 'Francis', 'lname' => 'Hwang' } )
	def assert_attributes( object, att_values )
		att_values.each { |method, expected|
			assert_equal( expected, object.send( method ), method.to_s )
		}
	end
	
	def default_test #:nodoc:
	end
end

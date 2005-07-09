require 'lafcadio/depend'
require 'lafcadio/mock'
require 'lafcadio/util'
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
	
	def default_test; end
end

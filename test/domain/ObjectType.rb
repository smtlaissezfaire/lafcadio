require 'lafcadio/domain/ObjectType'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/User'
require 'test/mock/domain/LineItem'
require 'test/mock/domain'

class TestObjectType < LafcadioTestCase
	def teardown
		if FileTest.exist?( 'test/testData/Attribute.xml.tmp' )
			`mv test/testData/Attribute.xml.tmp test/testData/Attribute.xml`
		end
		ObjectType.flush
	end

	def testTableName
		assert_equal( "users", ObjectType.getObjectType(User).tableName )
		assert_equal( "lineItems",
		              ObjectType.getObjectType(Domain::LineItem).tableName )
	end
	
	def testHandlesClassWithoutXml
		ot = ObjectType.getObjectType( NoXml )
		assert_equal( 'objId', ot.sqlPrimaryKeyName )
		assert_equal( 'noXmls', ot.tableName )
	end
	
	def test_informative_error_if_missing_class_data
		`mv test/testData/Attribute.xml test/testData/Attribute.xml.tmp`
		begin
			ObjectType.flush
			Attribute.getClassFields
			fail "Definitely needs to raise an Exception"
		rescue MissingError
			assert_equal( "Couldn't find either an XML class description file or " +
			              "getClassFields method for Attribute", $!.to_s )
		end
	end
end

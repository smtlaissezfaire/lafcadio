require 'lafcadio/mock/MockFieldManager'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'
require 'test/mock/domain/User'

class TestObjectField < LafcadioTestCase
	def setup
		super
		@client = Client.storedTestClient
		@user = User.new ({ "salutation" => "Mr", "firstNames" => "Francis",
				"lastName" => "Hwang", "phone" => "", "address1" => "",
				"address2" => "", "city" => "", "state" => "",
				"zip" => "", "email" => "test@test.com",
				"password" => "mypassword!", "objId" => 1 })
		@mockObjectStore.addObject @user
	end

  def testUniqueness
    field = ObjectField.new(Client, "name")
    field.unique = true
    errorCaught = false
    begin
      field.verify("clientName1", nil)
    rescue
      errorCaught = true
			assert_not_nil $!.to_s =~ /That name is already taken./, $!
    end
    assert errorCaught
    field.verify("clientName2", nil)
		field.notUniqueMsg = "That client already exists."
		errorCaught = false
		begin
			field.verify "clientName1", nil
		rescue
			errorCaught = true
			assert_not_nil $!.to_s =~ /That client already exists./
		end
		assert errorCaught
  end

  def testValueFromCGIHandlesWriteOnce
    field = ObjectField.new User, "email"
    field.writeOnce = true
    fm = MockFieldManager.new( { "objId" => "1", 'objectType' => 'Invoice'} )
    valueFromCGI = field.valueFromCGI fm
    assert_equal("test@test.com", valueFromCGI)
  end

  def testUniqueAllowsEditsOfSameRow
    field = ObjectField.new User, "email"
    field.unique = true
    field.verify ("test@test.com", 1)
  end

	def testNameForSQL
		field = ObjectField.new User, "id"
		field.dbFieldName = "objId"
		assert_equal "objId", field.nameForSQL
	end

	def testComparable
		field1 = ObjectField.new User, "firstNames"
		field2 = ObjectField.new User, "firstNames"
		assert_equal field1, field2
		field3 = ObjectField.new User, "lastName"
		assert field1 != field3
	end

	def testValueForSQL
    omf = ObjectField.new nil, "someField"
		assert_equal String, omf.valueForSQL(nil).type
		assert_equal 'null', omf.valueForSQL(nil)
	end
	
	def testValueFromSql
		of = ObjectField.new nil, 'someField'
		of.notNull = false
		valueFromSql = of.valueFromSQL(nil)
		assert_equal NilClass, valueFromSql.type
		assert_equal nil, valueFromSql
	end
end

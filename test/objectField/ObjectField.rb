require 'lafcadio/test'
require '../test/mock/domain/Client'
require '../test/mock/domain/User'

class TestObjectField < LafcadioTestCase
	def setup
		super
		@client = Client.storedTestClient
		@user = User.new({ "salutation" => "Mr", "firstNames" => "Francis",
				"lastName" => "Hwang", "phone" => "", "address1" => "",
				"address2" => "", "city" => "", "state" => "",
				"zip" => "", "email" => "test@test.com",
				"password" => "mypassword!", "pk_id" => 1 })
		@mockObjectStore.commit @user
	end

  def testUniqueness
    field = ObjectField.new(Client, "name")
    field.unique = true
    errorCaught = false
    begin
      field.verify("clientName1", nil)
    rescue
      errorCaught = true
			assert_not_nil $!.to_s =~ /That name already exists./, $!.to_s
    end
    assert errorCaught
    field.verify("clientName2", nil)
		errorCaught = false
		begin
			field.verify "clientName1", nil
		rescue
			errorCaught = true
			assert_not_nil $!.to_s =~ /That name already exists./
		end
		assert errorCaught
  end

  def testUniqueAllowsEditsOfSameRow
    field = ObjectField.new User, "email"
    field.unique = true
    field.verify("test@test.com", 1)
  end

	def testNameForSQL
		field = ObjectField.new User, "id"
		field.db_field_name = "pk_id"
		assert_equal "pk_id", field.name_for_sql
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
		assert_equal String, omf.value_for_sql(nil).class
		assert_equal 'null', omf.value_for_sql(nil)
	end
	
	def testValueFromSql
		of = ObjectField.new nil, 'someField'
		of.notNull = false
		valueFromSql = of.value_from_sql(nil)
		assert_equal NilClass, valueFromSql.class
		assert_equal nil, valueFromSql
	end
	
	def testVerifyFalseValue
		field = ObjectField.new( Client, 'name' )
		field.verify( false, nil )
	end
	
	def testEnglishName
		field = ObjectField.new( Client, 'name', 'client name' )
		assert_equal( 'client name', field.english_name )
	end
end

require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'
require 'test/mock/domain/User'

class TestObjectField < LafcadioTestCase
	def setup
		super
		@client = Client.storedTestClient
		@user = User.new({ "salutation" => "Mr", "firstNames" => "Francis",
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
			assert_not_nil $!.to_s =~ /That name is already taken./, $!.to_s
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

  def testUniqueAllowsEditsOfSameRow
    field = ObjectField.new User, "email"
    field.unique = true
    field.verify("test@test.com", 1)
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
		assert_equal String, omf.valueForSQL(nil).class
		assert_equal 'null', omf.valueForSQL(nil)
	end
	
	def testValueFromSql
		of = ObjectField.new nil, 'someField'
		of.notNull = false
		valueFromSql = of.valueFromSQL(nil)
		assert_equal NilClass, valueFromSql.class
		assert_equal nil, valueFromSql
	end
	
	class ObjectField_OLD
		def initialize(objectType, name, englishName = nil)
			require 'lafcadio/objectStore/ObjectStore'
	
			@objectType = objectType
			@name = name
			@dbFieldName = @name
			if englishName == nil
				@englishName = English.camelCaseToEnglish(name).capitalize
			else
				@englishName = englishName
			end
			@notNull = true
			@hideLabel = false
			@unique = false
			@default = nil
			@objectStore = ObjectStore.getObjectStore
		end
	end
	
	def measureSpeed
		startTime = Time.now
		100.times { yield }
		Time.now - startTime
	end
		
	def testOptimizeInitialize
		oldTime = measureSpeed { ObjectField_OLD.new User, "firstNames" }
		newTime = measureSpeed { ObjectField.new User, "firstNames" }
		ratio = oldTime / newTime
		assert ratio > 1.25, ratio.to_s
	end
	
	def testVerifyFalseValue
		field = ObjectField.new( Client, 'name' )
		field.verify( false, nil )
	end
	
	def testEnglishName
		field = ObjectField.new( Client, 'name', 'client name' )
		assert_equal( 'client name', field.englishName )
	end
end

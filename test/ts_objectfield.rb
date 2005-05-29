require 'dbi'
require 'lafcadio/test'
require 'lafcadio/objectField'
require 'lafcadio/objectStore'
require '../test/mock/domain'

class TestBooleanField < LafcadioTestCase
  def setup
  	super
    @bf = BooleanField.new(nil, "administrator")
  end

	def test_raise_error_if_no_enums_available
		@bf.enum_type = 999
		begin
			@bf.get_enums
			fail "should raise MissingError"
		rescue MissingError
			# ok
		end
	end

	def test_text_enums
		@bf.enums = { true => '1', false => '0' }
		assert_equal( "'1'", @bf.value_for_sql( true ) )
		assert_equal( "'0'", @bf.value_for_sql( false ) )
	end

  def testValueForSQL
    assert_equal(0, @bf.value_for_sql(false))
  end

	def testValueFromSQL
		assert_equal true, @bf.value_from_sql(1)
		assert_equal true, @bf.value_from_sql('1')
		assert_equal false, @bf.value_from_sql(0)
		assert_equal false, @bf.value_from_sql('0')
	end

	def testWithDifferentEnums
		bf2 = BooleanField.new nil, 'whatever'
		bf2.enum_type = BooleanField::ENUMS_CAPITAL_YES_NO
		assert_equal("'N'", bf2.value_for_sql(false))
		assert_equal true, bf2.value_from_sql('Y')
		assert_equal false, bf2.value_from_sql('N')
		bf3 = BooleanField.new nil, 'whatever'
		bf3.enums =({ true => '', false => 'N' })
		assert_equal true, bf3.value_from_sql('')
		assert_equal false, bf3.value_from_sql('N')
	end
end

class TestDateField < LafcadioTestCase
  def setup
  	super
    @odf = DateField.new Invoice
  end

  def testCatchesBadFormat
    begin
      @odf.verify("2001-04-05", nil)
      fail "Should raise an error with a bad value"
    rescue
			# ok
    end
    @odf.verify(Date.new(2001, 4, 5), nil)
  end

  def testNotNull
    odf1 = DateField.new nil
    assert(odf1.not_null)
    odf1.not_null = false
    assert(!odf1.not_null)
  end

  def testValueForSQL
    assert_equal("'2001-04-05'", @odf.value_for_sql(Date.new(2001, 4, 5)))
		assert_equal 'null', @odf.value_for_sql(nil)
  end

  def testValueFromSQL
		obj = @odf.value_from_sql( DBI::Date.new( 2001, 4, 5 ) )
    assert_equal(Date, obj.class)
		obj2 = @odf.value_from_sql( DBI::Date.new( 0, 0, 0 ) )
    assert_nil obj2
		obj3 = @odf.value_from_sql nil
		assert_nil obj3
  end
end

class TestDateTimeField < LafcadioTestCase
	def setup
		super
		@dateTimeField = DateTimeField.new nil, "datetime"
		@aug24 = Time.local(2002, "aug", 24, 13, 8, 22)
	end

	def testValueForSQL
		assert_equal "'2002-08-24 13:08:22'",(@dateTimeField.value_for_sql(@aug24))
		assert_equal "null", @dateTimeField.value_for_sql(nil)
	end

	def testValueFromSQL
		ts1 = DBI::Timestamp.new( 2002, 8, 24, 13, 8, 22 )
		value = @dateTimeField.value_from_sql ts1, false
		assert_equal Time, value.class
		assert_equal @aug24, value
		assert_nil(@dateTimeField.value_from_sql(nil))
		oct6 = Time.local(2002, "oct", 6, 0, 0, 0)
		dbi_oct6 = DBI::Timestamp.new( 2002, 10, 6 )
		assert_equal oct6,(@dateTimeField.value_from_sql dbi_oct6)
		assert_equal nil,(@dateTimeField.value_from_sql nil)
	end
end

class TestFloatField < LafcadioTestCase
  def setup
  	super
    @odf = FloatField.new( Invoice, "hours" )
  end

  def testNeedsNumeric
    caught = false
    begin
      @odf.verify("36.5", nil)
    rescue
      caught = true
    end
    assert(caught)
    @odf.verify(36.5, nil)
  end
  
  def testGetvalue_from_sql
    obj = @odf.value_from_sql "1.1"
    assert_equal(1.1, obj)    
  end

	def testValueForSQL
		assert_equal 'null', @odf.value_for_sql(nil)
	end
end

class TestEmailField < LafcadioTestCase
	def testValidAddress
		assert !EmailField.valid_address('a@a')
		assert !EmailField.valid_address('a.a@a')
		assert !EmailField.valid_address('a.a.a')
		assert !EmailField.valid_address('a')
		assert EmailField.valid_address('a@a.a')
		assert EmailField.valid_address('a,a@a.a')
		assert !EmailField.valid_address('a@a.a, my_friend_too@a.a')
		assert !EmailField.valid_address('cant have spaces @ this. that')
  end

  def testVerify
    field = EmailField.new User
		begin
			field.verify('a@a', nil)
			fail "didn't catch 'a@'"
		rescue FieldValueError
			# ok
		end
		field.not_null = false
		field.verify( nil, 1 )
	end
end

class TestEnumField < LafcadioTestCase
	def TestEnumField.getTestEnumField
		cardTypes = QueueHash.new( 'AX', 'American Express', 'MC', 'MasterCard',
				'VI', 'Visa', 'DS', 'Discover' )
		EnumField.new( User, "cardType", cardTypes )
	end

	def testSimpleEnumsArray
		field = EnumField.new User, "salutation", [ 'Mr', 'Mrs', 'Miss', 'Ms' ]
		enums = field.enums
		assert_equal 'Mr', enums['Mr']
	end
	
	def testValueForSql
		field = EnumField.new User, "salutation", [ 'Mr', 'Mrs', 'Miss', 'Ms' ]
		field.not_null = true
		assert_equal 'null', field.value_for_sql('')
	end
	
	def test_verify
		field = TestEnumField.getTestEnumField
		field.verify( 'AX', 1 )
		assert_raise( FieldValueError ) { field.verify( 'IOU', 1 ) }
		field.not_null = false
		field.verify( nil, 1 )
	end
end

class TestIntegerField < LafcadioTestCase
	def testValueFromSQL
		field = IntegerField.new nil, "number"
		assert_equal Fixnum, field.value_from_sql("1").class
		field.not_null = false
		assert_equal nil, field.value_from_sql(nil)
	end
end

class TestDomainObjectField < LafcadioTestCase
  def setup
		super
    @olf = DomainObjectField.new(nil, Client)
		@mockObjectStore.commit Client.new(
				{ "pk_id" => 1, "name" => "clientName1" } )
		@mockObjectStore.commit Client.new(
				{ "pk_id" => 2, "name" => "clientName2" } )
    @fieldWithListener = DomainObjectField.new(nil, Client, "client", "Client")
  end

  def testNameForSQL
    assert_equal("client", @olf.name_for_sql)
  end

  def testNames
    assert_equal("client", @olf.name)
		caDomainObjectField = DomainObjectField.new nil, InternalClient
		assert_equal "internal_client", caDomainObjectField.name
		liDomainObjectField = DomainObjectField.new nil, Domain::LineItem
		assert_equal "line_item", liDomainObjectField.name
  end

	def testRespectsOtherSubsetLinks
		invoice = Invoice.storedTestInvoice
		client = Client.storedTestClient
		client.priorityInvoice = invoice
		@mockObjectStore.commit client
		client2 = client.clone
		client2.pk_id = 2
		@mockObjectStore.commit client2
		domain_object_field = Invoice.get_class_field 'client'
		begin
			domain_object_field.verify(client2, 1)
			fail 'should throw FieldValueError'
		rescue FieldValueError
			# ok
		end
	end

  def testValueForSQL
    client = Client.new( { "name" => "my name", "pk_id" => 10 } )
    assert_equal(10, @olf.value_for_sql(client))
		badClient = Client.new({ 'name' => 'Bad client' })
		begin
			@olf.value_for_sql(badClient)
			fail 'needs to throw DBObjectInitError'
		rescue DomainObjectInitError
			# ok
		end
		assert_equal("null", @olf.value_for_sql(nil))
  end

	def testValueForSqlForProxies
		clientProxy = DomainObjectProxy.new(Client, 45)
		assert_equal 45, @olf.value_for_sql(clientProxy)
	end

  def testValueFromSQL
		client = Client.getTestClient
		@mockObjectStore.commit client
		clientFromDomainObjectField = @olf.value_from_sql("1")
		assert_equal DomainObjectProxy, clientFromDomainObjectField.class
		assert_equal client.name, clientFromDomainObjectField.name
		assert_nil @olf.value_from_sql(nil)
  end
end

class TestMonthField < LafcadioTestCase
	def setup
		super
		@field = MonthField.new nil, "expirationDate"
	end

	def testValueForSQL
		assert_equal( "'2005-12-01'",
		              @field.value_for_sql( Month.new( 2005, 12 ) ) )
	end

	def testVerifyMonths
		@field.verify( Month.new( 2005, 12 ), nil )
		caught = false
		begin
			@field.verify(Date.new(5, 12, 2005))
		rescue
			caught = true
		end
		assert caught
	end
end

class TestObjectField < LafcadioTestCase
	def setup
		super
		@client = Client.storedTestClient
		@user = User.new(
			"firstNames" => "Francis", "email" => "test@test.com", "pk_id" => 1
		)
		@mockObjectStore.commit @user
	end

	def testComparable
		field1 = ObjectField.new User, "firstNames"
		field2 = ObjectField.new User, "firstNames"
		assert_equal field1, field2
		field3 = ObjectField.new User, "lastName"
		assert field1 != field3
	end

	def testNameForSQL
		field = ObjectField.new User, "id"
		field.db_field_name = "pk_id"
		assert_equal "pk_id", field.name_for_sql
	end

	def testValueForSQL
    omf = ObjectField.new nil, "someField"
		assert_equal String, omf.value_for_sql(nil).class
		assert_equal 'null', omf.value_for_sql(nil)
	end
	
	def testValueFromSql
		of = ObjectField.new nil, 'someField'
		of.not_null = false
		valueFromSql = of.value_from_sql(nil)
		assert_equal NilClass, valueFromSql.class
		assert_equal nil, valueFromSql
	end
	
	def testVerifyFalseValue
		field = ObjectField.new( Client, 'name' )
		field.verify( false, nil )
	end
end

class TestStringField < LafcadioTestCase
  def setup
  	super
    @of = StringField.new(nil, "name")
  end

  def testvalue_for_sql
    assert_equal("'clientName1'", @of.value_for_sql("clientName1"))
    name = "John's Doe"
    assert_equal("'John''s Doe'", @of.value_for_sql(name))
    assert_equal("John's Doe", name)
		assert_equal("null",(@of.value_for_sql nil))
		assert_equal "'don\\\\'t substitute this apostrophe'",
				@of.value_for_sql("don\\'t substitute this apostrophe")
		assert_equal "'couldn''t, wouldn''t, shouldn''t'",
				@of.value_for_sql("couldn't, wouldn't, shouldn't")
		assert_equal "''' look, an apostrophe at the beginning'",
				@of.value_for_sql("' look, an apostrophe at the beginning")
		assert_equal "'I like '''' to use apostrophes!'",
				@of.value_for_sql("I like '' to use apostrophes!")
		backslash = "\\"
		assert_equal "'EXH: #{ backslash * 6 }'",
				@of.value_for_sql("EXH: #{ backslash * 3 }")
		assert_equal "'#{ backslash * 2 }'", @of.value_for_sql(backslash)
		assert_equal( "'// ~  $ #{ backslash * 4 }\n" +
		              "some other line\napostrophe''s'",
									@of.value_for_sql( "// ~  $ #{ backslash * 2 }\n" +
									                 "some other line\napostrophe's" )
							  )
		assert_equal( "'Por favor, don''t just forward the icon through email\n" +
		              "''cause then you won''t be able to see ''em through the " +
									"web interface.'",
									@of.value_for_sql( "Por favor, don't just forward the icon " +
									                 "through email\n'cause then you won't be " +
																	 "able to see 'em through the web " +
																	 "interface." ) )
		assert_equal( "'three: '''''''", @of.value_for_sql( "three: '''" ) )
		assert_equal( "''''''''", @of.value_for_sql( "'''" ) )
		assert_equal( "''''''''''''", @of.value_for_sql( "'''''" ) )
		assert_equal( "'\n''''''the defense asked if two days of work'",
		              @of.value_for_sql( "\n'''the defense asked if two days of " +
									                 "work" ) )
  end
end

class TestTextListField < LafcadioTestCase
	def setup
		super
		@tlf = TextListField.new nil, 'whatever'
	end

	def testValueForSQL
		assert_equal "'a,b,c'",(@tlf.value_for_sql([ 'a', 'b', 'c' ]))
		assert_equal "''",(@tlf.value_for_sql([ ]))
		assert_equal( "'abc'", @tlf.value_for_sql( 'abc' ) )
	end

	def testValueFromSQL
		array = @tlf.value_from_sql('a,b,c')
		assert_not_nil array.index('a')
		assert_not_nil array.index('b')
		assert_not_nil array.index('c')
		assert_equal 3, array.size
		array = @tlf.value_from_sql(nil)
		assert_equal 0, array.size
	end
end
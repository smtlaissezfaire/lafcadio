require 'lafcadio/test'
require '../test/mock/domain'

class TestTextField < LafcadioTestCase
  def setup
  	super
    @of = TextField.new(nil, "name")
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

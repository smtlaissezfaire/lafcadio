require 'lafcadio/mock/MockFieldManager'
require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Client'

class TestTextField < LafcadioTestCase
  def setup
  	super
    @of = TextField.new(nil, "name")
  end

  def testvalueForSQL
    assert_equal("'clientName1'", @of.valueForSQL("clientName1"))
    name = "John's Doe"
    assert_equal("'John''s Doe'", @of.valueForSQL(name))
    assert_equal("John's Doe", name)
		assert_equal("null", @of.valueForSQL nil)
		assert_equal "'don\\\\'t substitute this apostrophe'",
				@of.valueForSQL("don\\'t substitute this apostrophe")
		assert_equal "'couldn''t, wouldn''t, shouldn''t'",
				@of.valueForSQL("couldn't, wouldn't, shouldn't")
		assert_equal "''' look, an apostrophe at the beginning'",
				@of.valueForSQL("' look, an apostrophe at the beginning")
		assert_equal "'I like '''' to use apostrophes!'",
				@of.valueForSQL("I like '' to use apostrophes!")
		backslash = "\\"
		assert_equal "'EXH: #{ backslash * 6 }'",
				@of.valueForSQL("EXH: #{ backslash * 3 }")
		assert_equal "'#{ backslash * 2 }'", @of.valueForSQL(backslash)
  end

  def testEnglishName
    skuField = TextField.new nil, "sku", "SKU"
    assert_equal "SKU", skuField.englishName
  end

	def testValueFromCGIMakesBlankIntoNil
		mfm = MockFieldManager.new ({ 'name' => '' })
		assert_nil @of.valueFromCGI (mfm)
	end
end

require 'lafcadio/test'
require 'lafcadio/util'

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
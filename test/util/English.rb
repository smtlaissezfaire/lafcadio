require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/util/English'

class TestEnglish < LafcadioTestCase
  def testCamelCaseToEnglish
    assert_equal "product category",
				English.camelCaseToEnglish("productCategory")
		assert_equal "product category",
				English.camelCaseToEnglish("ProductCategory")
		assert_equal 'catalog order',
				English.camelCaseToEnglish('catalogOrder')
		assert_equal 'product', English.camelCaseToEnglish('product')
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
		assert_equal "Albania", English.properNoun("albania")
		assert_equal "Bosnia and Herzegovina",
				English.properNoun("bosnia and herzegovina")
		assert_equal "Faroe Islands", English.properNoun("faroe islands")
		assert_equal "Macedonia, the Former Yugoslav Republic of",
				English.properNoun("macedonia, the former yugoslav republic of")
		assert_equal "Virgin Islands, U.S.",
				English.properNoun("virgin islands, u.s.")
	end

	def testStartsWithVowelSound
		assert English.startsWithVowelSound('order')
		assert !English.startsWithVowelSound('catalogOrder')
		assert !English.startsWithVowelSound('user')
	end

	def testSingular
		assert_equal 'tree', English.singular('trees')
		assert_equal 'fairy', English.singular('fairies')
		assert_equal 'address', English.singular('addresses')
	end
end
require 'lafcadio/test/LafcadioTestCase'

class TestEnglishUtil < LafcadioTestCase
  def testCamelCaseToEnglish
    assert_equal "product category",
				EnglishUtil.camelCaseToEnglish("productCategory")
		assert_equal "product category",
				EnglishUtil.camelCaseToEnglish("ProductCategory")
  end

  def testSentence
    sentence = EnglishUtil.sentence("There %is currently %num %nam",
				"product category", 0)
    assert_equal("There are currently 0 product categories", sentence)
		sentence2 = EnglishUtil.sentence("Add %a %nam", "sku")
		assert_equal("Add a sku", sentence2)
		sentence3 = EnglishUtil.sentence("Add %a %nam", "invoice")
		assert_equal("Add an invoice", sentence3)
		sentence4 = EnglishUtil.sentence("Add %a %nam", 'user')
		assert_equal 'Add a user', sentence4
  end

  def testPlural
    assert_equal "product categories", EnglishUtil.plural("product category")
    assert_equal "products", EnglishUtil.plural("product")
		assert_equal 'addresses', EnglishUtil.plural('address')
		assert_equal 'taxes', EnglishUtil.plural('tax')
  end

	def testProperNoun
		assert_equal "Albania", EnglishUtil.properNoun("albania")
		assert_equal "Bosnia and Herzegovina",
				EnglishUtil.properNoun("bosnia and herzegovina")
		assert_equal "Faroe Islands", EnglishUtil.properNoun("faroe islands")
		assert_equal "Macedonia, the Former Yugoslav Republic of",
				EnglishUtil.properNoun("macedonia, the former yugoslav republic of")
		assert_equal "Virgin Islands, U.S.",
				EnglishUtil.properNoun("virgin islands, u.s.")
	end

	def testStartsWithVowelSound
		assert EnglishUtil.startsWithVowelSound('order')
		assert !EnglishUtil.startsWithVowelSound('catalogOrder')
		assert !EnglishUtil.startsWithVowelSound('user')
	end

	def testSingular
		assert_equal 'tree', EnglishUtil.singular('trees')
		assert_equal 'fairy', EnglishUtil.singular('fairies')
		assert_equal 'address', EnglishUtil.singular('addresses')
	end
end
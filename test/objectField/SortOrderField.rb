require 'lafcadio/mock/MockFieldManager'
require 'lafcadio/test/LafcadioTestCase'
require 'lafcadio/mock/MockObjectStore'
require 'test/mock/domain/Option'
require 'lafcadio/objectField/SortOrderField'

class TestSortOrderField < LafcadioTestCase
	def setup
		super
		@sortOrderField = SortOrderField.new Option
	end

	def testValueFromCGI
		mfm = MockFieldManager.new( { "objectType" => "Option",
																		"attribute" => "1", "name" => "small" } )
		assert_equal 2, @sortOrderField.valueFromCGI(mfm)
		@mockObjectStore.addObject TestOption.getTestOption
		assert_equal 3, @sortOrderField.valueFromCGI(mfm)
	end

	def testPrevValueFromCGI
		fieldHash = { "objectType" => "Option", "attribute" => "1",
									"name" => "small", "objId" => "1" }
		mfm = MockFieldManager.new fieldHash
		@mockObjectStore.addObject TestOption.getTestOption
		assert_equal 1, @sortOrderField.valueFromCGI(mfm)
	end

	def setupThreeSpacedOptions
		fieldHash = { "attribute" => TestAttribute.getTestAttribute,
									'name' => 'option name 1', 'sortOrder' => 5, "objId" => 1 }
		@option1 = Option.new fieldHash
		fieldHash['sortOrder'] = 10
		fieldHash['objId'] = 2
		@option2 = Option.new fieldHash
		fieldHash['sortOrder'] = 15
		fieldHash['objId'] = 3
		@option3 = Option.new fieldHash
		@mockObjectStore.addObject @option1
		@mockObjectStore.addObject @option2
		@mockObjectStore.addObject @option3
	end

	def testValueAsHTML
		setupThreeSpacedOptions
		html1 = @sortOrderField.valueAsHTML @option1
		assert_nil html1.index(@sortOrderField.glyph("up", 1))
		assert_not_nil html1.index(@sortOrderField.glyph("down", 1)), html1
		html2 = @sortOrderField.valueAsHTML @option2
		assert_not_nil html2.index(@sortOrderField.glyph("up", 2))
		assert_not_nil html2.index(@sortOrderField.glyph("down", 2))
		html3 = @sortOrderField.valueAsHTML @option3
		assert_not_nil html3.index(@sortOrderField.glyph("up", 3))
		assert_nil html3.index(@sortOrderField.glyph("down", 3))
	end
end
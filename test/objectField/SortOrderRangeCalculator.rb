require 'lafcadio/test/LafcadioTestCase'
require 'test/mock/domain/Attribute'
require 'lafcadio/mock/MockObjectStore'
require 'lafcadio/objectField/SortOrderRangeCalculator'

class TestSortOrderRangeCalculator < LafcadioTestCase
	def setupThreeSpacedOptions
		fieldHash = { "attribute" => TestAttribute.storedTestAttribute,
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

	def testSortWithinHTML
		setupThreeSpacedOptions
		attribute2 = Attribute.new ( { "objId" => 2, "name" => 'attribute 2' } )
		@mockObjectStore.addObject attribute2
		fieldHash = { "attribute" => attribute2, 'name' => 'option name 4',
									'sortOrder' => 20, "objId" => 4 }
		option4 = Option.new fieldHash
		@mockObjectStore.addObject option4
		sortOrderField = SortOrderField.new Option
		sortOrderField.sortWithin = Attribute
		allRelatedObjects = sortOrderField.allRelatedObjects option4
		calculator = SortOrderRangeCalculator.new sortOrderField, allRelatedObjects
		range = calculator.execute
		assert_equal 20, range.begin
		assert_equal 20, range.end
	end
end

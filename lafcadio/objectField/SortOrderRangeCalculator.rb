class SortOrderRangeCalculator
	def initialize(sortOrderField, allRelatedObjects)
		@sortOrderField = sortOrderField
		@allRelatedObjects = allRelatedObjects
		@objectStore = Context.instance.getObjectStore
	end

	def getSortOrderRange(allRelatedObjects)
		highestSortOrder = 0
		lowestSortOrder = nil
		allRelatedObjects.each { |anObj|
			otherSortOrder = anObj.send(@sortOrderField.name)
			highestSortOrder = otherSortOrder if otherSortOrder > highestSortOrder
			if lowestSortOrder == nil
				lowestSortOrder = otherSortOrder
			else
				lowestSortOrder = otherSortOrder if otherSortOrder < lowestSortOrder
			end
		}
		(lowestSortOrder..highestSortOrder)
	end

	def execute
		getSortOrderRange @allRelatedObjects
	end
end
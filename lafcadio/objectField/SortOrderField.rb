require 'lafcadio/objectField/IntegerField'

class SortOrderField < IntegerField
	attr_accessor :sortWithin

	def initialize(objectType, name = "sortOrder", englishName = "Sort order")
		super objectType, name, englishName
		@sortWithin = nil
	end

	def valueFromCGI(fieldManager)
		if firstTime fieldManager
			highestSortOrder = 0
			objectStore = Context.instance.getObjectStore
			objectStore.getAll(@objectType).each { |obj|
				highestSortOrder = obj.send(name) if obj.send(name) > highestSortOrder
			}
			highestSortOrder + 2
		else
			prevValue fieldManager.getObjId
		end
	end
end

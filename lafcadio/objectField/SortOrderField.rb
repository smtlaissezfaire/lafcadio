require 'lafcadio/objectField/IntegerField'

class SortOrderField < IntegerField
	attr_accessor :sortWithin

	def initialize(objectType, name = "sortOrder", englishName = "Sort order")
		super objectType, name, englishName
		@sortWithin = nil
	end
end

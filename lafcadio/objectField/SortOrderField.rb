require 'lafcadio/objectField/IntegerField'
require 'lafcadio/html/A'
require 'lafcadio/objectField/SortOrderRangeCalculator'
require 'lafcadio/objectField/SortOrderFieldViewer'
require 'lafcadio/objectField/SortOrderField'

class SortOrderField < IntegerField
	def SortOrderField.viewerType
		SortOrderFieldViewer
	end

	attr_accessor :sortWithin

	def initialize (objectType, name = "sortOrder", englishName = "Sort order")
		super objectType, name, englishName
		@sortWithin = nil
	end

	def valueFromCGI (fieldManager)
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

	def glyph (direction, objId)
		href = "/cgi-bin/editSortOrder.rb?objectType=Option&objId=#{objId}&" +
				"direction=#{direction}"
		arrow = direction == "up" ? "^" : "v"
		HTML::A.new({ 'href' => href }, arrow).toHTML
	end

	def allRelatedObjects (dbObject)
		allRelatedObjs = @objectStore.getAll(dbObject.type)
		if @sortWithin !=  nil
			sortWithinFieldName = @sortWithin.name.downcase
			sortWithinValue = dbObject.send(sortWithinFieldName)
			allRelatedObjs = allRelatedObjs.filterObjects(sortWithinFieldName,
					sortWithinValue)
		end
		allRelatedObjs
	end

	def valueAsHTML (dbObject)
		calculator = SortOrderRangeCalculator.new self, allRelatedObjects(dbObject)
		sortOrderRange = calculator.execute
		sortOrder = super dbObject
		glyphs = []
		if sortOrder != sortOrderRange.begin
			glyphs << glyph("up", dbObject.objId)
		else
			glyphs << "&nbsp;"
		end
		if sortOrder != sortOrderRange.end
			glyphs << glyph("down", dbObject.objId)
		else
			glyphs << "&nbsp;"
		end
		glyphs.join ' '
	end
end

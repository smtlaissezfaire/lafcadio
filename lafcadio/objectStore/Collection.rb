class Collection < Array
	attr_reader :objectType, :filteredByName, :filteredByValue

  def initialize(objectType, filteredByName = nil, filteredByValue = nil)
		unless objectType && objectType <= DomainObject
			raise "Collection can only store DomainObjects"
		end
    @objectType = objectType
		@filteredByName = filteredByName
		@filteredByValue = filteredByValue
  end

	def elementCompare(x, y, accessors)
		xSortValue = x.send(accessors[0])
		ySortValue = y.send(accessors[0])
		if xSortValue.respond_to? 'upcase'
			xSortValue = xSortValue.upcase
			ySortValue = ySortValue.upcase
		end
		cmp = xSortValue <=> ySortValue
		if cmp == 0 && accessors.size > 1
			elementCompare x, y, accessors[1..accessors.size-1]
		else
			cmp
		end
	end

	def sort!( accessors = [ 'objId' ] )
		if block_given?
			super &(proc { |x, y| yield(x, y) } )
		else
			super &(proc { |x, y| elementCompare(x, y, accessors) } )
		end
	end

	def sort( accessors = [ 'objId' ] )
		otherColl = self.clone
		if block_given?
			otherColl.sort! { |x, y| yield(x, y) }
		else
			otherColl.sort! accessors
		end
		otherColl
	end

	def filter(fieldName = nil, searchTerm = nil)
    filteredCollection = Collection.new @objectType, fieldName,
				searchTerm
		if(fieldName && searchTerm)
	    each { |obj|
  	    filteredCollection << obj if obj.send(fieldName) == searchTerm
    	}
		else
			each { |obj| filteredCollection << obj if yield obj }
		end
    filteredCollection
	end

  def filterByBlock
		filter { |obj| yield obj }
  end

  def filterObjects(fieldName, searchTerm)
		filter fieldName, searchTerm
  end

	def remove(fieldName, searchTerm)
		filter { |obj| obj.send(fieldName) != searchTerm }
	end

  def removeObjects(fieldName, searchTerm)
		remove fieldName, searchTerm
  end
end


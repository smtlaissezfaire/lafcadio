# A collection for domain objects.
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

	# Sorts the elements in place. If a block is given, then the elements are 
	# sorted according to the block. Otherwise, the elements are sorted, in rank 
	# of descending priority, by the fields named in the <tt>accessors</tt> array. 
	# For example, a name sort of users might look like
	#   userCollection.sort! ([ 'lastName', 'firstNames' ])
	# If no accessors are given, sort! sorts by objId.
	def sort!( accessors = [ 'objId' ] )
		if block_given?
			super &(proc { |x, y| yield(x, y) } )
		else
			super &(proc { |x, y| elementCompare(x, y, accessors) } )
		end
	end

	# Returns a copy of this collection with its elements sorted. If a block is 
	# given, then the elements are sorted according to the block. Otherwise, the 
	# elements are sorted, in rank of descending priority, by the fields named in 
	# the <tt>accessors</tt> array. For example, a name sort of users might look 
	# like
	#   sortedCollection = userCollection.sort ([ 'lastName', 'firstNames' ])
	# If no accessors are given, sort sorts by objId.
	def sort( accessors = [ 'objId' ] )
		otherColl = self.clone
		if block_given?
			otherColl.sort! { |x, y| yield(x, y) }
		else
			otherColl.sort! accessors
		end
		otherColl
	end

	# Returns a copy of this collection with only certain elements. If 
	# <tt>fieldName</tt> and <tt>searchTerm</tt> are set, then filter will only 
	# return domain objects such that
	#   obj.send(fieldName) == searchTerm
	# Otherwise, filter expects to receive a block, and returns all domain objects 
	# for which the block evaluates to <tt>true</tt>.
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

	# Returns a copy of this collection, first removing every domain object for 
	# which
	#   obj.send(fieldName) != searchTerm
	def remove(fieldName, searchTerm)
		filter { |obj| obj.send(fieldName) != searchTerm }
	end

  def removeObjects(fieldName, searchTerm)
		remove fieldName, searchTerm
  end
end


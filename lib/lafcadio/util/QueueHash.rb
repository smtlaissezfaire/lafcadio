module Lafcadio
	# An ordered hash: Keys are ordered according to when they were inserted.
	class QueueHash
		# Creates a QueueHash with all the elements in <tt>array</tt> as keys, and 
		# each value initially set to be the same as the corresponding key.
		def QueueHash.newFromArray(array)
			valueArray = []
			array.each { |elt|
				valueArray << elt
				valueArray << elt
			}
			new(*valueArray)
		end

		# Takes an even number of arguments, and sets each odd-numbered argument to 
		# correspond to the argument immediately afterward. For example:
		#   queueHash = QueueHash.new (1, 2, 3, 4)
		#   queueHash[1] => 2
		#   queueHash[3] => 4
		def initialize(*values)
			@pairs = []
			0.step(values.size-1, 2) { |i| @pairs << [ values[i], values[i+1] ] }
		end

		def keys
			keys = []
			@pairs.each { |pair| keys << pair[0] }
			keys
		end

		def values
			values = []
			@pairs.each { |pair| values << pair[1] }
			values
		end

		def [](key)
			value = nil
			@pairs.each { |pair| value = pair[1] if pair[0] == key }
			value
		end

		def size
			@pairs.size
		end

		def []=(key, value)
			@pairs << [key, value]
		end

		def each
			@pairs.each { |pair| yield pair[0], pair[1] }
		end
		
		def ==( otherObj )
			if otherObj.class == QueueHash && otherObj.size == size
				match = true
				(0...size).each { |i|
					match &&= keys[i] == otherObj.keys[i] && values[i] == otherObj.values[i]
				}
				match
			else
				false
			end
		end
	end
end
module Lafcadio
	# A hash where each value is guaranteed to be an array or nil.
	class HashOfArrays
		def initialize
			@values = {}
		end

		def set(key, array)
			raise "HashOfArrays.[]= needs a value of type Array" if array.class != Array
			@values[key] = array
		end

		def []=(key, array)
			set key, array
		end

		def getArray(key)
			array = @values[key]
			if array == nil
				array = []
				@values[key] = array
			end
			array
		end

		def get(key)
			array = @values[key]
			array != nil ? array[0] : nil
		end

		def [](key)
			getArray key
		end

		def values
			values = []
			@values.values.each { |val| values << val[0] }
			values
		end

		def keys
			@values.keys
		end

		def each
			@values.each { |key, array| yield key, array }
		end
	end
end
require 'delegate'

module Lafcadio
	# An ordered hash: Keys are ordered according to when they were inserted.
	class QueueHash < DelegateClass( Array )
		# Creates a QueueHash with all the elements in <tt>array</tt> as keys, and 
		# each value initially set to be the same as the corresponding key.
		def self.newFromArray(array)
			new( *( ( array.map { |elt| [ elt, elt ] } ).flatten ) )
		end

		# Takes an even number of arguments, and sets each odd-numbered argument to 
		# correspond to the argument immediately afterward. For example:
		#   queueHash = QueueHash.new (1, 2, 3, 4)
		#   queueHash[1] => 2
		#   queueHash[3] => 4
		def initialize(*values)
			@pairs = []
			0.step(values.size-1, 2) { |i| @pairs << [ values[i], values[i+1] ] }
			super( @pairs )
		end
		
		def ==( otherObj )
			if otherObj.class == QueueHash && otherObj.size == size
				( 0..size ).all? { |i|
					keys[i] == otherObj.keys[i] && values[i] == otherObj.values[i]
				}
			else
				false
			end
		end

		def [](key); ( @pairs.find { |pair| pair[0] == key } )[1]; end

		def []=(key, value); @pairs << [key, value]; end

		def each; @pairs.each { |pair| yield pair[0], pair[1] }; end

		def keys; @pairs.map { |pair| pair[0] }; end

		def values; @pairs.map { |pair| pair[1] }; end
	end
end
require 'lafcadio/includer'
Includer.include( 'objectField' )

module Lafcadio
	class AutoIncrementField < IntegerField # :nodoc:
		attr_reader :objectType

		def initialize(objectType, name, englishName = nil)
			super(objectType, name, englishName)
			@objectType = objectType
		end

		def HTMLWidgetValueStr(value)
			if value != nil
				super value
			else
				highestValue = 0
				ObjectStore.getObjectStore.getAll(objectType).each { |obj|
					aValue = obj.send(name).to_i
					highestValue = aValue if aValue > highestValue
				}
			 (highestValue + 1).to_s
			end
		end
	end

	# BlobField stores a string value and expects to store its value in a BLOB
	# field in the database.
	class BlobField < ObjectField
		attr_accessor :size

		def bind_write?; true; end #:nodoc:

		def valueForSQL(value); "?"; end #:nodoc:
	end
end
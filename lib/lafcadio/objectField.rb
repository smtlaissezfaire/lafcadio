require 'lafcadio/includer'
Includer.include( 'objectField' )

module Lafcadio
	# BlobField stores a string value and expects to store its value in a BLOB
	# field in the database.
	class BlobField < ObjectField
		attr_accessor :size

		def bind_write?; true; end #:nodoc:

		def valueForSQL(value); "?"; end #:nodoc:
	end
end
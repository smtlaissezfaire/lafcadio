require 'lafcadio/includer'
Includer.include( 'objectField' )

module Lafcadio
	class BlobField < ObjectField
		attr_accessor :size

		def bind_write?; true; end

		def valueForSQL(value); "?"; end
	end
end
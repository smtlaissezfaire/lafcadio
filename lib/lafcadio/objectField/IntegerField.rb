require 'lafcadio/objectField/ObjectField'

module Lafcadio
	# IntegerField represents an integer.
	class IntegerField < ObjectField
		def textBoxSize #:nodoc:
			5
		end

		def valueFromSQL(string) #:nodoc:
			value = super
			value ? value.to_i : nil
		end
	end
end
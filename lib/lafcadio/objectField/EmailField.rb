require 'lafcadio/objectField/TextField'
require 'lafcadio/objectField/FieldValueError'

module Lafcadio
	# EmailField takes a text value that is expected to be formatted as a single
	# valid email address.
	class EmailField < TextField
		# Is +address+ a valid email address?
		def self.validAddress(address)
			address =~ /^[^ @]+@[^ \.]+\.[^ ,]+$/
		end

		def initialize(objectType, name = "email", englishName = nil)
			super(objectType, name, englishName)
		end

		def nullErrorMsg #:nodoc:
			"Please enter an email address."
		end

		def verify(value, pkId) #:nodoc:
			super(value, pkId)
			if !EmailField.validAddress(value)
				raise FieldValueError, "Please enter a valid email address.", caller
			end
		end
	end
end
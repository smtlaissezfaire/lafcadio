require 'lafcadio/objectField/TextField'
require 'lafcadio/objectField/FieldValueError'

module Lafcadio
	class EmailField < TextField
		def EmailField.validAddress(address)
			address =~ /^[^ @]+@[^ \.]+\.[^ ,]+$/
		end

		def initialize(objectType, name = "email", englishName = nil)
			super(objectType, name, englishName)
		end

		def nullErrorMsg
			"Please enter an email address."
		end

		def verify(value, pkId)
			super(value, pkId)
			if !EmailField.validAddress(value)
				raise FieldValueError, "Please enter a valid email address.", caller
			end
		end
	end
end
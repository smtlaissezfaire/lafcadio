require 'lafcadio/objectField/ObjectField'

module Lafcadio
	# A TextField is expected to contain a string value.
	class TextField < ObjectField
		def valueForSQL(value) #:nodoc:
			if value
				value = value.gsub(/(\\?')/) { |m| m.length == 1 ? "''" : m }
				value = value.gsub(/\\/) { '\\\\' }
				"'#{value}'"
			else
				"null"
			end
		end
	end
end

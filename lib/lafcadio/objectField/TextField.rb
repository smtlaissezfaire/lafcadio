require 'lafcadio/objectField/ObjectField'

module Lafcadio
	class TextField < ObjectField
		attr_accessor :large, :size

		def initialize(objectType, name, englishName = nil)
			super objectType, name, englishName
			@large = false
		end

		def valueForSQL(value)
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

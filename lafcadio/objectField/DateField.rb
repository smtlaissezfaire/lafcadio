require 'lafcadio/objectField/ObjectField'
require 'date'

module Lafcadio
	class DateField < ObjectField
		RANGE_NEAR_FUTURE = 0
		RANGE_PAST = 1

		def DateField.valueType
			Date
		end

		attr_accessor :range

		def initialize(objectType, name = "date", englishName = nil)
			super(objectType, name, englishName)
			@range = RANGE_NEAR_FUTURE
		end

		def valueForSQL(value)
			value ? "'#{value.to_s}'" : 'null'
		end

		def valueFromSQL(dbiDate, lookupLink = true)
			begin
				dbiDate ? dbiDate.to_date : nil
			rescue ArgumentError
				nil
			end
		end
	end
end
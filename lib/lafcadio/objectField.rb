require 'lafcadio/includer'
Includer.include( 'objectField' )
require 'date'
require 'lafcadio/util'

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

	# BooleanField represents a boolean value. By default, it assumes that the
	# table field represents True and False with the integers 1 and 0. There are
	# two different ways to change this default.
	#
	# First, BooleanField includes a few enumerated defaults. Currently there are
	# only
	#   * BooleanField::ENUMS_ONE_ZERO (the default, uses integers 1 and 0)
	#   * BooleanField::ENUMS_CAPITAL_YES_NO (uses characters 'Y' and 'N')
	# In the XML class definition, this field would look like
	#   <field name="field_name" class="BooleanField"
	#          enumType="ENUMS_CAPITAL_YES_NO"/>
	# If you're defining a field in Ruby, simply set BooleanField#enumType to one
	# of the values.
	#
	# For more fine-grained specification you can pass specific values in. Use
	# this format for the XML class definition:
	#   <field name="field_name" class="BooleanField">
	#     <enums>
	#       <enum key="true">yin</enum>
	#       <enum key="false">tang</enum>
	#     </enums>
	#   </field>
	# If you're defining the field in Ruby, set BooleanField#enums to a hash.
	#   myBooleanField.enums = { true => 'yin', false => 'yang' }
	#
	# +enums+ takes precedence over +enumType+.
	class BooleanField < ObjectField
		ENUMS_ONE_ZERO = 0
		ENUMS_CAPITAL_YES_NO = 1

		attr_accessor :enumType, :enums

		def initialize(objectType, name, englishName = nil)
			super(objectType, name, englishName)
			@enumType = ENUMS_ONE_ZERO
			@enums = nil
		end

		def falseEnum # :nodoc:
			getEnums[false]
		end

		def getEnums( value = nil ) # :nodoc:
			if @enums
				@enums
			elsif @enumType == ENUMS_ONE_ZERO
				if value.class == String
					{ true => '1', false => '0' }
				else
					{ true => 1, false => 0 }
				end
			elsif @enumType == ENUMS_CAPITAL_YES_NO
				{ true => 'Y', false => 'N' }
			else
				raise MissingError
			end
		end

		def textEnumType # :nodoc:
			@enums ? @enums[true].class == String : @enumType == ENUMS_CAPITAL_YES_NO
		end

		def trueEnum( value = nil ) # :nodoc:
			getEnums( value )[true]
		end

		def valueForSQL(value) # :nodoc:
			if value
				vfs = trueEnum
			else
				vfs = falseEnum
			end
			textEnumType ? "'#{vfs}'" : vfs
		end

		def valueFromSQL(value, lookupLink = true) # :nodoc:
			value == trueEnum( value )
		end
	end

	# DateField represents a Date.
	class DateField < ObjectField
		RANGE_NEAR_FUTURE = 0
		RANGE_PAST = 1

		def self.valueType # :nodoc:
			Date
		end

		attr_accessor :range

		def initialize(objectType, name = "date", englishName = nil)
			super(objectType, name, englishName)
			@range = RANGE_NEAR_FUTURE
		end

		def valueForSQL(value) # :nodoc:
			value ? "'#{value.to_s}'" : 'null'
		end

		def valueFromSQL(dbiDate, lookupLink = true) # :nodoc:
			begin
				dbiDate ? dbiDate.to_date : nil
			rescue ArgumentError
				nil
			end
		end
	end
	
	# DateTimeField represents a DateTime.
	class DateTimeField < ObjectField
		def valueForSQL(value) # :nodoc:
			if value
				year = value.year
				month = value.mon.to_s.pad( 2, "0" )
				day = value.day.to_s.pad( 2, "0" )
				hour = value.hour.to_s.pad( 2, "0" )
				minute = value.min.to_s.pad( 2, "0" )
				second = value.sec.to_s.pad( 2, "0" )
				"'#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}'"
			else
				"null"
			end
		end

		def valueFromSQL(dbi_value, lookupLink = true) # :nodoc:
			dbi_value ? dbi_value.to_time : nil
		end
	end
	
	# Accepts a Month as a value. This field automatically saves in MySQL as a 
	# date corresponding to the first day of the month.
	class MonthField < DateField
		def self.valueType #:nodoc:
			Month
		end

		def valueForSQL(value) #:nodoc:
			"'#{value.year}-#{value.month}-01'"
		end
	end

	class TimeStampField < DateTimeField #:nodoc:
		def initialize(objectType, name = 'timeStamp', englishName = nil)
			super( objectType, name, englishName )
			@notNull = false
		end

		def dbWillAutomaticallyWrite
			true
		end
	end
end
require 'lafcadio/objectField/ObjectField'
require 'lafcadio/objectField/BooleanFieldViewer'

# BooleanField represents a boolean value. By default, it assumes that the table 
# field represents true and false with the integers 1 and 0. For a field that 
# deviates from this default, you can set the enumeration one of two ways.
# 1. Set BooleanField#enumType one of the enums preset values. Currently there 
#    are only
#    * BooleanField::ENUMS_ONE_ZERO (the default, uses integers 1 and 0)
#    * BooleanField::ENUMS_CAPITAL_YES_NO (uses characters 'Y' and 'N')
# 1. Set BooleanField#enums to a hash with keys <tt>true</tt> and 
#    <tt>false</tt>. For example:
#      myBooleanField.enums = { true => 'yin', false => 'yang' }
# <tt>enums</tt> takes precedence over <tt>enumType</tt>.
class BooleanField < ObjectField
	ENUMS_ONE_ZERO = 0
	ENUMS_CAPITAL_YES_NO = 1

	def BooleanField.viewerType
		BooleanFieldViewer
	end

	attr_accessor :enumType, :enums

  def initialize(objectType, name, englishName = nil)
		super(objectType, name, englishName)
		@enumType = ENUMS_ONE_ZERO
	end

	def getEnums
		if @enums
			@enums
		elsif @enumType == ENUMS_ONE_ZERO
			{ true => '1', false => '0' }
		elsif @enumType == ENUMS_CAPITAL_YES_NO
			{ true => 'Y', false => 'N' }
		end
	end

	def trueEnum
		getEnums[true]
	end

	def falseEnum
		getEnums[false]
	end

	def textEnumType
		@enumType == ENUMS_CAPITAL_YES_NO
	end

  def valueForSQL(value)
    if value
			vfs = trueEnum
    else
			vfs = falseEnum
    end
		textEnumType ? "'#{vfs}'" : vfs
  end

	def valueFromSQL(value, lookupLink = true)
		value == trueEnum
	end

	def valueFromCGI(fieldManager)
		value = super fieldManager
		value != nil ? value : false
	end
end

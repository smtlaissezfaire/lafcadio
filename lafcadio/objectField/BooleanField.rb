require 'lafcadio/objectField/ObjectField'
require 'lafcadio/objectField/BooleanFieldViewer'

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

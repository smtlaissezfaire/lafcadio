require 'lafcadio/objectField/TextField'

class EnumField < TextField
	def EnumField.viewerType
		require 'lafcadio/objectField/EnumFieldViewer'
		EnumFieldViewer
	end

	attr_reader :enums

	def initialize(objectType, name, enums, englishName = nil)
		require 'lafcadio/util/QueueHash'
		super objectType, name, englishName
		if enums.class == Array 
			@enums = QueueHash.newFromArray enums
		else
			@enums = enums
		end
	end
	
	def valueForSQL(value)
		value != '' ?(super(value)) : 'null'
	end
end


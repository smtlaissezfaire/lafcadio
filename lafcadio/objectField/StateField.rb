require 'lafcadio/util/UsStates'
require 'lafcadio/objectField/EnumField'

class StateField < EnumField
	def initialize(objectType, name = "state", englishName = nil)
		super objectType, name, UsStates.states, englishName
	end
end


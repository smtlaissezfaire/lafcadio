require 'lafcadio/util/UsStates'
require 'lafcadio/objectField/EnumField'

module Lafcadio
	# A StateField is a specialized subclass of EnumField; its possible values are
	# any of the 50 states of the United States, stored as each state's two-letter
	# postal code.
	class StateField < EnumField
		def initialize(objectType, name = "state", englishName = nil)
			super objectType, name, UsStates.states, englishName
		end
	end
end

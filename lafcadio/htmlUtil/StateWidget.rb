require 'lafcadio/util/UsStates'
require 'lafcadio/html/Select'

class StateWidget
	def initialize(name = 'state', selectedState = nil)
		@name = name
		@selectedState = selectedState
	end

	def toHTML
		select = HTML::Select.new({ 'name' => @name })
		select.selected = @selectedState
		UsStates.states.each { |stateCode, stateName|
			select.addOption stateCode, stateName
		}
		select.toHTML
	end
end
require 'lafcadio/util/UsStates'
require 'lafcadio/html/Select'

class StateWidget
	# [name] The name of the field
	# [selectedState] The two letter postal code for the state that is 
	#                 pre-selected by the widget.
	def initialize(name = 'state', selectedState = nil)
		@name = name
		@selectedState = selectedState
	end

	# Returns an HTML string for use in a form.
	def toHTML
		select = HTML::Select.new({ 'name' => @name })
		select.selected = @selectedState
		UsStates.states.each { |stateCode, stateName|
			select.addOption stateCode, stateName
		}
		select.toHTML
	end
end
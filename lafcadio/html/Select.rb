require 'lafcadio/html/Option'

class HTML
	class Select < ContainerElement
		def Select.attributes
			[ 'name', 'onChange' ]
		end

		def Select.requiredAttributes
			[ 'name' ]
		end

		attr_accessor :selected

	  def addOption(value, displayName = value)
			attHash = { 'value' => value, 'selected' =>(selected == value) }
  	  self << HTML::Option.new(attHash, displayName)
	  end
	end
end
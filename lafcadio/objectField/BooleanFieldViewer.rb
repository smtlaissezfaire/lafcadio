require 'lafcadio/objectField/FieldViewer'
require 'lafcadio/html/Checkbox'

class BooleanFieldViewer < FieldViewer
	def toHTMLWidget
		checkbox = HTML::Checkbox.new ({ 'name' => @field.name })
		checkbox.checked = @value
		checkbox.toHTML
	end
end
require 'lafcadio/html/Select'
require 'lafcadio/objectField/FieldViewer'
require 'lafcadio/html/HTML'

class EnumFieldViewer < FieldViewer
  def toHTMLWidget
		if @field.enums.keys.size < 10
			text = HTML.new
			@field.enums.keys.each { |value|
    	  tag = "<input type='radio' name='#{@field.name}' value='#{value}'"
      	tag += " checked" if @value.to_s == value.to_s
	      tag += ">"
				text << "#{tag} #{@field.enums[value]}"
				text.addBR
			}
			text.toHTML
		else
			select = HTML::Select.new({ 'name' => @field.name })
			select.selected = @value
			if !@field.notNull
				select.addOption '', ''
			end
			@field.enums.keys.each { |value|
				select.addOption value, @field.enums[value]
			}
			select.toHTML
		end
	end
end
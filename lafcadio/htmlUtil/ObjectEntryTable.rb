require 'lafcadio/html/Table'
require 'lafcadio/html/TD'

class ObjectEntryTable < HTML::Table
	def initialize
		super ({ 'bgcolor' => '#dddddd', 'cellpadding' => 5, 'cellspacing' => 5 })
	end

	def addRow (label, widget)
		row = HTML::TR.new
		row << HTML::Strong.new(label)
		rightCell = HTML::TD.new ({ 'bgcolor' => '#ffffff' }, widget )
		row << rightCell
		self << row
	end

	def addField (field, value = nil)
		addRow field.englishName, field.viewer(value, nil).toHTMLWidget
	end

	def addSubmit
		require 'lafcadio/html/InputSubmit'
		row = HTML::TR.new
		row << ""
		row << HTML::TD.new ( {}, HTML::InputSubmit.new )
		self << row
	end
end


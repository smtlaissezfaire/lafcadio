require 'lafcadio/html/TR'
require 'lafcadio/html/ContainerElement'

class HTML < Array
	class Table < ContainerElement
		def Table.attributes
			[ 'bgcolor', 'cellpadding', 'cellspacing', 'border' ]
		end

		def Table.requiredAttributes
			[ ]
		end

  	attr_accessor :bgColor, :cellPadding, :cellSpacing, :border

	  def << (element)
			require 'lafcadio/html/Form'
			if element != nil
				if element.type <= HTML::TR || element.type <= HTML::Form
					super element
				else
      	  raise "Can't insert object of type #{element.type} into Table"
    	  end
	    end
  	end

		def numColumns
			numColumns = 0
			each { |row| numColumns = row.size if row.size > numColumns }
			numColumns
		end

		def insertColumn
			(0..size-1).each { |i|
				newRow = HTML::TR.new
				newRow << ""
				newRow = newRow.concat self[i]
				self[i] = newRow
			}
		end

		def toTDF
			rowTDFs = []
			self.each { |row| rowTDFs << row.toTDF }
			rowTDFs.join "\n"
		end
	end
end
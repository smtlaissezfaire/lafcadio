require 'lafcadio/html/ContainerElement'
require 'lafcadio/html/TD'

class HTML < Array
	class TR < ContainerElement
		def TR.attributes
			[ 'align', 'valign', 'bgcolor' ]
		end

		def eltHTML(elt)
			if elt.class == TD
				elt.toHTML
			elsif elt =~ /^<td/
				elt
			else
				" " + HTML::TD.new( {}, elt).toHTML
			end
		end

		def toTDF
			contents = []
			self.each { |cell|
				if cell.respond_to? 'contents'
					contents << cell.contents
				else
					contents << cell
				end
			}
			contents.join "\t"
		end
	end
end


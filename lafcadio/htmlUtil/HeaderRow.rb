require 'lafcadio/html/TR'
require 'lafcadio/html/TD'

class HeaderRow < HTML::TR
	def initialize (attHash = {}, firstElts = nil)
		if firstElts == nil || firstElts.type != Array
			super attHash, firstElts
		else
			super attHash
			firstElts.each { |elt| self << elt }
		end
	end

	def << (elt)
		unless elt.type <= String || elt.type <= HTML::TD
			fail "HeaderRow can only hold Strings or TDs"
		end
		super elt
	end

	def eltHTML (elt)
		if elt.type <= String
			elt = elt.gsub (/ /, '&nbsp;')
			HTML::TD.new({}, HTML::Strong.new(elt)).toHTML
		else
			elt[0] = HTML::Strong.new(elt[0])
			elt.toHTML
		end
	end
end
module Lafcadio
	module DomainComparable
		include Comparable

		def <=>(anOther)
			if anOther.respond_to?( 'objectType' )
				if self.objectType == anOther.objectType
					self.objId <=> anOther.objId
				else
					self.objectType.name <=> anOther.objectType.name
				end
			else
				nil
			end
		end
		
		def eql?(otherObj)
			self == otherObj
		end
	end
end
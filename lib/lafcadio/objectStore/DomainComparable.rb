module Lafcadio
	module DomainComparable
		include Comparable

		# A DomainObject or DomainObjectProxy is compared by +objectType+ and by
		# +pkId+. 
		def <=>(anOther)
			if anOther.respond_to?( 'objectType' )
				if self.objectType == anOther.objectType
					self.pkId <=> anOther.pkId
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

		def hash; "#{ self.class.name } #{ pkId }".hash; end
	end
end
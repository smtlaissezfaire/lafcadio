module DomainComparable
	include Comparable

	def <=> (anOther)
		if self.objectType == anOther.objectType
			self.objId <=> anOther.objId
		else
			self.objectType.name <=> anOther.objectType.name
		end
	end
	
	def eql? (otherObj)
		self == otherObj
	end
end
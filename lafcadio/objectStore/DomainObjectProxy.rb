require 'lafcadio/objectStore/DomainComparable'

class DomainObjectProxy
	include DomainComparable

	attr_accessor :objectType, :objId

	def initialize (objectTypeOrDbObject, objId = nil)
		if objId
			@objectType = objectTypeOrDbObject
			@objId = objId
		else
			dbObject = objectTypeOrDbObject
			@objectType = dbObject.type
			@objId = dbObject.objId
		end
	end

	def getDbObject
		Context.instance.getObjectStore.get(@objectType, @objId)
	end

	def method_missing (methodId)
		getDbObject.send(methodId.id2name)
	end

	def to_s
		getDbObject.to_s
	end

	def hash
		getDbObject.hash
	end
end


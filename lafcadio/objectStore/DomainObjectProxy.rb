require 'lafcadio/objectStore/DomainComparable'

# The DomainObjectProxy is used when retrieving domain objects that are linked 
# to other domain objects with LinkFields. In terms of objectType and objId, a 
# DomainObjectProxy instance looks to the outside world like the domain object 
# it's supposed to represent. It only retrieves its domain object from the 
# database when member data is requested.
class DomainObjectProxy
	include DomainComparable

	attr_accessor :objectType, :objId

	def initialize(objectTypeOrDbObject, objId = nil)
		if objId
			@objectType = objectTypeOrDbObject
			@objId = objId
		elsif objectTypeOrDbObject.class < DomainObject
			dbObject = objectTypeOrDbObject
			@objectType = dbObject.class
			@objId = dbObject.objId
		else
			raise ArgumentError
		end
	end

	def getDbObject
		Context.instance.getObjectStore.get(@objectType, @objId)
	end

	def method_missing(methodId, *args)
		getDbObject.send(methodId.id2name, *args)
	end

	def to_s
		getDbObject.to_s
	end

	def hash
		getDbObject.hash
	end
end


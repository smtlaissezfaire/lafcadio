require 'lafcadio/objectStore/DomainComparable'

module Lafcadio
	# The DomainObjectProxy is used when retrieving domain objects that are 
	# linked to other domain objects with LinkFields. In terms of objectType and 
	# pkId, a DomainObjectProxy instance looks to the outside world like the 
	# domain object it's supposed to represent. It only retrieves its domain 
	# object from the database when member data is requested.
	class DomainObjectProxy
		include DomainComparable

		attr_accessor :objectType, :pkId

		def initialize(objectTypeOrDbObject, pkId = nil)
			if pkId
				@objectType = objectTypeOrDbObject
				@pkId = pkId
			elsif objectTypeOrDbObject.class < DomainObject
				dbObject = objectTypeOrDbObject
				@objectType = dbObject.class
				@pkId = dbObject.pkId
			else
				raise ArgumentError
			end
		end

		def getDbObject
			Context.instance.getObjectStore.get(@objectType, @pkId)
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
end

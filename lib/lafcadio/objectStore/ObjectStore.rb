require 'lafcadio'

module Lafcadio
	# The ObjectStore represents the database in a Lafcadio application.
	#
	# There are a few important dynamic method names used by ObjectStore:
	#
	# [ObjectStore#get< domain class > (objId)]
	#   Retrieves one domain object by objId. For example,
	#     ObjectStore#getUser (100)
	#   will return User 100.
	# [ObjectStore#get< domain class >s (searchTerm, fieldName = nil)]
	#   Looks for instances of that domain class matching that search term. For
	#   example,
	#     ObjectStore#getProducts (aProductCategory)
	#   queries MySQL for all products that belong to that product category. If 
	#   <tt>fieldName</tt> isn't given, it's inferred from the 
	#   <tt>searchTerm</tt>. This works well for a search term that is a domain 
	#   object, but for something more prosaic you'll probably need to set 
	#   <tt>fieldName</tt> explicitly:
	#     ObjectStore#getUsers ("Jones", "lastName")
	class ObjectStore < ContextualService
		def ObjectStore.setDbName(dbName)
			DbBridge.setDbName dbName
		end
		
		def initialize(context, dbBridge = nil)
			super context
			require 'lafcadio/objectStore/Collector'
			require 'lafcadio/objectStore/Retriever'
			@dbBridge = dbBridge == nil ? DbBridge.new : dbBridge
			@retriever = ObjectStore::Retriever.new(@dbBridge)
			@collector = Lafcadio::Collector.new self
		end

		# Commits a domain object to the database. You can also simply call
		#   myDomainObject.commit
		def commit(dbObject)
			require 'lafcadio/objectStore/Committer'
			committer = Committer.new dbObject, @dbBridge
			committer.execute
			if committer.commitType == Committer::UPDATE ||
					committer.commitType == Committer::INSERT
				@retriever.set dbObject
			elsif committer.commitType == Committer::DELETE
				@retriever.clear dbObject
			end
		end

		def get(objectType, objId)
			@retriever.get objectType, objId
		end
		
		def getDbBridge; @dbBridge; end

		def getLastCommit(dbObject)
			if dbObject.delete
				DomainObject::COMMIT_DELETE
			elsif dbObject.objId
				DomainObject::COMMIT_EDIT
			else
				DomainObject::COMMIT_ADD
			end
		end

		def getAll(objectType)
			@retriever.getAll objectType
		end

		# Returns a collection of domain objects that correspond to the Condition 
		# or Query. This queries the database for only the relevant objects, and as 
		# such can offer significant time savings over retrieving all the objects 
		# and then filtering them in Ruby.
		def getSubset(conditionOrQuery)
			if conditionOrQuery.class <= Query::Condition
				condition = conditionOrQuery
				query = Query.new condition.objectType, condition
			else
				query = conditionOrQuery
			end
			@dbBridge.getCollectionByQuery query
		end

		def method_missing(methodId, *args)
			subsystems = { 'collector' => @collector, 'dbBridge' => @dbBridge,
			               'retriever' => @retriever }
			proc = block_given? ? ( proc { |obj| yield( obj ) } ) : nil
			dispatcher = MethodDispatcher.new( subsystems, methodId, proc, *args )
			dispatcher.execute
		end
	end
end

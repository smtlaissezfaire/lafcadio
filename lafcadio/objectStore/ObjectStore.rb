require 'lafcadio/objectStore/Collector'
require 'lafcadio/objectStore/CouldntMatchObjectTypeError'
require 'lafcadio/objectStore/Retriever'
require 'lafcadio/objectStore/Committer'
require 'lafcadio/objectStore/DbBridge'
require 'lafcadio/util/Context'
require 'lafcadio/util/ContextualService'
require 'lafcadio/util/DomainUtil'

class ObjectStore < ContextualService
	def ObjectStore.setDbName (dbName)
		DbBridge.setDbName dbName
	end
  
  def initialize (context, dbBridge = nil)
  	super context
		@dbBridge = dbBridge == nil ? DbBridge.new : dbBridge
		@retriever = ObjectStore::Retriever.new(@dbBridge)
		@collector = Collector.new self
  end

	def get (objectType, objId)
		@retriever.get objectType, objId
	end

	def getLastCommit (dbObject)
		if dbObject.delete
			DomainObject::COMMIT_DELETE
		elsif dbObject.objId
			DomainObject::COMMIT_EDIT
		else
			DomainObject::COMMIT_ADD
		end
	end

  def commit (dbObject)
  	committer = Committer.new dbObject, @dbBridge
  	committer.execute
		if committer.commitType == Committer::UPDATE
			@retriever.set dbObject
		elsif committer.commitType == Committer::DELETE
			@retriever.clear dbObject
		end
  end

  def getAll (objectType)
		@retriever.getAll objectType
  end

	def getSubset (conditionOrQuery)
		if conditionOrQuery.type <= Query::Condition
			condition = conditionOrQuery
			query = Query.new condition.objectType, condition
		else
			query = conditionOrQuery
		end
		@dbBridge.getCollectionByQuery query
	end

	def method_missing (methodId, *args)
		methodName = methodId.id2name
		begin
			methodName =~ /^get(.*)$/
			objectType = DomainUtil.getObjectTypeFromString $1
			get objectType, args[0]
		rescue CouldntMatchObjectTypeError
			subsystems = [ @collector, @dbBridge, @retriever ]
			resolved = false
			while (subsystems.size > 0 && !resolved)
				subsystem = subsystems.shift
				begin
					result = subsystem.send methodName, *args
					resolved = true
				rescue CouldntMatchObjectTypeError
					# try the next one
				end
			end
			if resolved
				result
			else
				super methodId
			end
		end		
	end
end


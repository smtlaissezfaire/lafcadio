require 'lafcadio/objectStore/ObjectStore'

class Committer
	INSERT 	= 1
	UPDATE 	= 2
	DELETE  = 3

	attr_reader :commitType

	def initialize (dbObject, dbBridge)
		@dbObject = dbObject
		@dbBridge = dbBridge
		@objectStore = Context.instance.getObjectStore
		@commitType = nil
	end
	
	def setCommitType
		if @dbObject.delete
			@commitType = DELETE
		elsif @dbObject.objId
			@commitType = UPDATE
		else
			@commitType = INSERT
		end
	end

	def execute
		setCommitType
    @dbObject.lastCommit = @objectStore.getLastCommit (@dbObject)
		@dbObject.preCommitTrigger
    if @dbObject.delete
      dependentClasses = @dbObject.objectType.dependentClasses
      dependentClasses.keys.each { |aClass|
        field = dependentClasses[aClass]
        collection = @objectStore.getAll(aClass).filterObjects(
        		field.name, @dbObject)
        collection.each { |dependentObject|
					eval %{ dependentObject.#{field.name} = nil }
					@objectStore.commit (dependentObject)
        }
      }
    end
    @dbBridge.commit @dbObject
		unless @dbObject.objId
			@dbObject.objId = @dbBridge.lastObjIdInserted
		end
		@dbObject.postCommitTrigger
	end
end

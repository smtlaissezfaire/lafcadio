require 'lafcadio/objectStore/ObjectStore'

# Commits one domain object to the database.
class Committer
	INSERT 	= 1
	UPDATE 	= 2
	DELETE  = 3

	attr_reader :commitType

	# [dbObject] The domain object to be committed.
	# [dbBridge] The DbBridge.
	def initialize(dbObject, dbBridge)
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

	# Executes the commit. Note that this handles all Ruby-level details of 
	# commits, such as triggers. The actual work of sending a SQL statement to the 
	# database is handled by the DbBridge.
	def execute
		setCommitType
    @dbObject.lastCommit = @objectStore.getLastCommit(@dbObject)
		@dbObject.preCommitTrigger
    if @dbObject.delete
      dependentClasses = @dbObject.objectType.dependentClasses
      dependentClasses.keys.each { |aClass|
        field = dependentClasses[aClass]
				collection = @objectStore.getFiltered( aClass.name, @dbObject,
				                                       field.name )
        collection.each { |dependentObject|
					eval %{ dependentObject.#{field.name} = nil }
					@objectStore.commit(dependentObject)
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

require 'lafcadio/objectStore/ObjectStore'

module Lafcadio
	# Commits one domain object to the database.
	class Committer
		INSERT 	= 1
		UPDATE 	= 2
		DELETE  = 3

		attr_reader :commitType, :dbObject

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
			elsif @dbObject.pkId
				@commitType = UPDATE
			else
				@commitType = INSERT
			end
		end

		# Executes the commit. Note that this handles all Ruby-level details of 
		# commits, such as triggers. The actual work of sending a SQL statement to 
		# the database is handled by the DbBridge.
		def execute
			setCommitType
			@dbObject.lastCommit = getLastCommit
			@dbObject.preCommitTrigger
			if @dbObject.delete
				dependentClasses = @dbObject.objectType.dependentClasses
				dependentClasses.keys.each { |aClass|
					field = dependentClasses[aClass]
					collection = @objectStore.getFiltered( aClass.name, @dbObject,
																								 field.name )
					collection.each { |dependentObject|
						if field.deleteCascade
							dependentObject.delete = true
						else
							dependentObject.send( field.name + '=', nil )
						end
						@objectStore.commit(dependentObject)
					}
				}
			end
			@dbBridge.commit @dbObject
			unless @dbObject.pkId
				@dbObject.pkId = @dbBridge.lastPkIdInserted
			end
			@dbObject.postCommitTrigger
		end
		
		def getLastCommit
			if @dbObject.delete
				DomainObject::COMMIT_DELETE
			elsif @dbObject.pkId
				DomainObject::COMMIT_EDIT
			else
				DomainObject::COMMIT_ADD
			end
		end
	end
end
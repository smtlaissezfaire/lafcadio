require 'lafcadio/objectStore/ObjectStore'

module Lafcadio
	class Committer #:nodoc:
		INSERT 	= 1
		UPDATE 	= 2
		DELETE  = 3

		attr_reader :commitType, :dbObject

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
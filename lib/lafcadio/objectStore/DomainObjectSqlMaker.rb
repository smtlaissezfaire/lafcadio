require 'lafcadio/objectStore/DomainObjectInitError'

module Lafcadio
	# Generates the necessary SQL for committing one domain object to the 
	# database.
	class DomainObjectSqlMaker
		attr_reader :bindValues

		def initialize(obj); @obj = obj; end

		def insertSQL(objectType)
			fields = objectType.classFields
			nameValuePairs = getNameValuePairs(objectType)
			if objectType.isBasedOn?
				nameValuePairs[objectType.sqlPrimaryKeyName] = 'LAST_INSERT_ID()'
			end
			fieldNameStr = nameValuePairs.keys.join ", "
			fieldValueStr = nameValuePairs.values.join ", "
			"insert into #{ objectType.tableName}(#{fieldNameStr}) " +
					"values(#{fieldValueStr})"
		end

		def getNameValuePairs(objectType)
			require 'lafcadio/util/QueueHash'
			nameValues = []
			objectType.classFields.each { |field|
				value = @obj.send(field.name)
				unless field.dbWillAutomaticallyWrite
					nameValues << field.nameForSQL
					nameValues <<(field.valueForSQL(value))
				end
				if field.bind_write?
					@bindValues << value
				end
			}
			QueueHash.new *nameValues
		end

		def updateSQL(objectType)
			nameValueStrings = []
			nameValuePairs = getNameValuePairs(objectType)
			nameValuePairs.each { |key, value|
				nameValueStrings << "#{key}=#{ value }"
			}
			allNameValues = nameValueStrings.join ', '
			"update #{ objectType.tableName} set #{allNameValues} " +
					"where #{ objectType.sqlPrimaryKeyName}=#{@obj.objId}"
		end

		def deleteSql(objectType)
			"delete from #{ objectType.tableName} " +
					"where #{ objectType.sqlPrimaryKeyName }=#{ @obj.objId }"
		end

		def sqlStatements
			statements = []
			if @obj.errorMessages.size > 0
				raise DomainObjectInitError, @obj.errorMessages, caller
			end
			@obj.class.selfAndConcreteSuperclasses.each { |objectType|
				@bindValues = []
				if @obj.objId == nil
					statement = insertSQL(objectType)
				else
					if @obj.delete
						statement = deleteSql(objectType)
					else
						statement = updateSQL(objectType)
					end
				end
				statements << [statement, @bindValues]
 			}
			statements.reverse
		end
	end
end

require 'lafcadio/objectStore'
require 'lafcadio/util'

module Lafcadio
	class DomainObjectSqlMaker #:nodoc:
		attr_reader :bindValues

		def initialize(obj); @obj = obj; end

		def deleteSql(objectType)
			"delete from #{ objectType.tableName} " +
					"where #{ objectType.sqlPrimaryKeyName }=#{ @obj.pkId }"
		end

		def getNameValuePairs(objectType)
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
			QueueHash.new( *nameValues )
		end

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

		def sqlStatements
			statements = []
			if @obj.errorMessages.size > 0
				raise DomainObjectInitError, @obj.errorMessages, caller
			end
			@obj.class.selfAndConcreteSuperclasses.each { |objectType|
				statements << statement_bind_value_pair( objectType )
 			}
			statements.reverse
		end

		def statement_bind_value_pair( objectType )
			@bindValues = []
			if @obj.pkId == nil
				statement = insertSQL(objectType)
			else
				if @obj.delete
					statement = deleteSql(objectType)
				else
					statement = updateSQL(objectType)
				end
			end
			[statement, @bindValues]
		end

		def updateSQL(objectType)
			nameValueStrings = []
			nameValuePairs = getNameValuePairs(objectType)
			nameValuePairs.each { |key, value|
				nameValueStrings << "#{key}=#{ value }"
			}
			allNameValues = nameValueStrings.join ', '
			"update #{ objectType.tableName} set #{allNameValues} " +
					"where #{ objectType.sqlPrimaryKeyName}=#{@obj.pkId}"
		end
	end
end

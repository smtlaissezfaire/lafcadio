require 'lafcadio/util'

module Lafcadio
	class Query
		class Condition #:nodoc:
			def Condition.searchTermType
				Object
			end

			attr_reader :objectType

			def initialize(fieldName, searchTerm, objectType)
				require 'lafcadio/domain/DomainObject'

				@fieldName = fieldName
				@searchTerm = searchTerm
				unless @searchTerm.class <= self.class.searchTermType
					raise "Incorrect searchTerm type #{ searchTerm.class }"
				end
				@objectType = objectType
				if @objectType
					unless @objectType <= DomainObject
						raise "Incorrect object type #{ @objectType.to_s }"
					end
				end
			end
			
			def primaryKeyField?
				[ @objectType.sqlPrimaryKeyName, 'pkId' ].include?( @fieldName )
			end
			
			def dbFieldName
				if primaryKeyField?
					db_table = @objectType.tableName
					db_field_name = @objectType.sqlPrimaryKeyName
					"#{ db_table }.#{ db_field_name }"
				else
					getField.db_table_and_field_name
				end
			end
			
			def getField
				anObjectType = @objectType
				field = nil
				while (anObjectType < DomainObject || anObjectType < DomainObject) &&
							!field
					field = anObjectType.getClassField @fieldName
					anObjectType = anObjectType.superclass
				end
				if field
					field
				else
					errStr = "Couldn't find field \"#{ @fieldName }\" in " +
									 "#{ @objectType } domain class"
					raise( MissingError, errStr, caller )
				end
			end
			
			def not
				require 'lafcadio/query/Not'
				Query::Not.new( self )
			end
		end
	end
end
require 'lafcadio/objectField'

module Lafcadio
	class CreateTableStatement #:nodoc:
		@@simple_field_clauses = {
			DecimalField => 'float', DateField => 'date', BooleanField => 'bool',
			TimeStampField => 'timestamp', DateTimeField => 'datetime'
		}
	
		def initialize( domainClass )
			@domainClass = domainClass
		end
		
		def definition_terms( field )
			definitionTerms = []
			definitionTerms << field.dbFieldName
			definitionTerms << typeClause( field )
			definitionTerms << 'not null' if field.notNull
			definitionTerms << 'unique' if field.unique
			definitionTerms.join( ' ' )
		end

		def toSql
			createDefinitions = []
			createDefinitions << "#{ @domainClass.sqlPrimaryKeyName } " +
													 "int not null auto_increment"
			createDefinitions << "primary key (#{ @domainClass.sqlPrimaryKeyName })"
			@domainClass.classFields.each { |field|
				createDefinitions << definition_terms( field )
			}
			<<-SQL
	create table #{ @domainClass.tableName } (
		#{ createDefinitions.join(",\n  ") }
	);
			SQL
		end
		
		def typeClause( field )
			if ( type_clause = @@simple_field_clauses[field.class] )
				type_clause
			elsif ( field.class <= EnumField )
				singleQuotedValues = field.enums.keys.collect! { |enumValue|
					"'#{ enumValue }'"
				}
				"enum( #{ singleQuotedValues.join( ', ' ) } )"
			elsif ( field.class <= TextField || field.class <= TextListField )
				'varchar(255)'
			elsif ( field.class <= LinkField || field.class <= IntegerField )
				'int'
			elsif ( field.class <= DecimalField )
				'float(10, 2)'
			elsif ( field.class <= BlobField )
				'blob'
			end
		end
	end
end
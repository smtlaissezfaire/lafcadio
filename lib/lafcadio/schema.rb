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
			definitionTerms << field.db_field_name
			definitionTerms << type_clause( field )
			definitionTerms << 'not null' if field.not_null
			definitionTerms << 'unique' if field.unique
			definitionTerms.join( ' ' )
		end

		def to_sql
			createDefinitions = []
			createDefinitions << "#{ @domainClass.sql_primary_key_name } " +
													 "int not null auto_increment"
			createDefinitions << "primary key (#{ @domainClass.sql_primary_key_name })"
			@domainClass.class_fields.each { |field|
				createDefinitions << definition_terms( field )
			}
			<<-SQL
	create table #{ @domainClass.table_name } (
		#{ createDefinitions.join(",\n  ") }
	);
			SQL
		end
		
		def type_clause( field )
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
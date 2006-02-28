require 'lafcadio/objectField'

module Lafcadio
	class CreateTableStatement #:nodoc:
		@@simple_field_clauses = {
			BooleanField => 'bool', BinaryField => 'blob', DateField => 'date', 
			DomainObjectField => 'int', FloatField => 'float',
			DateTimeField => 'datetime', IntegerField => 'int',
			StringField => 'varchar(255)', TextListField => 'varchar(255)',
			TimeStampField => 'timestamp'
		}
	
		def initialize( domain_class )
			@domain_class = domain_class
		end
		
		def definition_terms( field )
			definitionTerms = []
			definitionTerms << field.db_field_name
			definitionTerms << type_clause( field )
			definitionTerms << 'not null' if field.not_nil
			definitionTerms.join( ' ' )
		end

		def to_sql
			createDefinitions = []
			createDefinitions <<
				"#{ @domain_class.sql_primary_key_name } int not null auto_increment"
			createDefinitions <<
					"primary key (#{ @domain_class.sql_primary_key_name })"
			@domain_class.class_fields.each { |field|
				createDefinitions << definition_terms( field )
			}
			<<-SQL
create table #{ @domain_class.table_name } (
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
			end
		end
	end
end
module Lafcadio
	class CreateTableStatement #:nodoc:
		def initialize( domainClass )
			@domainClass = domainClass
		end
		
		def typeClause( field )
			require 'lafcadio/objectField/TextField'
			require 'lafcadio/objectField/DecimalField'
			require 'lafcadio/objectField/LinkField'
			require 'lafcadio/objectField/IntegerField'
			require 'lafcadio/objectField/DateField'
			require 'lafcadio/objectField/EnumField'
			require 'lafcadio/objectField/TextListField'
			require 'lafcadio/objectField/BooleanField'
			require 'lafcadio/objectField/DateTimeField'
			if ( field.class <= EnumField )
				singleQuotedValues = field.enums.keys.collect! { |enumValue|
					"'#{ enumValue }'"
				}
				"enum( #{ singleQuotedValues.join( ', ' ) } )"
			elsif ( field.class <= TextField || field.class <= TextListField )
				'varchar(255)'
			elsif field.class <= DecimalField
				"float"
			elsif ( field.class <= LinkField || field.class <= IntegerField )
				'int'
			elsif field.class <= DateField
				'date'
			elsif field.class <= BooleanField
				'bool'
			elsif field.class <= TimeStampField
				'timestamp'
			elsif field.class <= DateTimeField
				'datetime'
			end
		end
		
		def toSql
			createDefinitions = []
			createDefinitions << "#{ @domainClass.sqlPrimaryKeyName } " +
													 "int not null auto_increment"
			createDefinitions << "primary key (#{ @domainClass.sqlPrimaryKeyName })"
			@domainClass.classFields.each { |field|
				definitionTerms = []
				definitionTerms << field.dbFieldName
				definitionTerms << typeClause( field )
				definitionTerms << 'not null' if field.notNull
				definitionTerms << 'unique' if field.unique
				createDefinitions << definitionTerms.join(' ')
			}
			<<-SQL
	create table #{ @domainClass.tableName } (
		#{ createDefinitions.join(",\n  ") }
	);
			SQL
		end
	end
end
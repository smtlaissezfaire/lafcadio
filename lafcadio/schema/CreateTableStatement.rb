class CreateTableStatement
	def initialize( domainClass )
		@domainClass = domainClass
	end
	
	def typeClause( field )
		if field.class == TextField
			'varchar(255)'
		elsif field.class <= DecimalField
			"float(10, #{ field.precision })"
		elsif field.class <= LinkField
			'int'
		end
	end
	
	def toSql
		createDefinitions = []
		createDefinitions << "#{ @domainClass.sqlPrimaryKeyName } " +
												 "int not null auto_increment"
		createDefinitions << "primary key (#{ @domainClass.sqlPrimaryKeyName })"
		@domainClass.classFields.each { |field|
			definitionTerms = []
			definitionTerms << field.name
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
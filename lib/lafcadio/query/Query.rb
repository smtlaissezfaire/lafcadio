module Lafcadio
	# Manages the generation of SQL for one query.
	class Query
		ASC		= 1
		DESC 	= 2

		attr_reader :objectType, :condition
		attr_accessor :orderBy, :orderByOrder, :limit

		# [objectType] The domain class being searched.
		# [objIdOrCondition] If this is an Integer, it will search for only the 
		#                    object with that objId. If this is a Condition, it 
		#                    will search for a collection that matches that 
		#                    condition.
		def initialize(objectType, objIdOrCondition = nil)
			@objectType = objectType
			if objIdOrCondition
				if objIdOrCondition.class <= Condition
					@condition = objIdOrCondition
				else
					@condition = Query::Equals.new(objectType.sqlPrimaryKeyName,
							objIdOrCondition, objectType)
				end
			end
			@orderByOrder = ASC
		end
		
		def hash; toSql.hash; end
		
		def eql?( other )
			other.class <= Query && other.toSql == toSql
		end

		def tables
			tableNames = []
			anObjectType = objectType
			until(DomainObject.abstractSubclasses.index(anObjectType) != nil ||
					anObjectType == DomainObject)
				tableNames.unshift anObjectType.tableName
				anObjectType = anObjectType.superclass
			end
			tableNames.join ', '
		end

		def whereClause
			whereClauses = []
			anObjectType = objectType
			superclass = anObjectType.superclass
			until(DomainObject.abstractSubclasses.index(superclass) != nil ||
					superclass == DomainObject)
				joinClause = "#{ sqlPrimaryKeyField(superclass) } = " +
						"#{ sqlPrimaryKeyField(anObjectType) }"
				whereClauses.unshift joinClause
				anObjectType = superclass
				superclass = superclass.superclass
			end
			whereClauses << @condition.toSql if @condition
			if whereClauses.size > 0
				"where #{ whereClauses.join(' and ') }"
			else
				nil
			end
		end

		def sqlPrimaryKeyField(objectType)
			"#{ objectType.tableName }.#{ objectType.sqlPrimaryKeyName }"
		end

		def fields
			'*'
		end

		def orderClause
			if @orderBy
				clause = "order by #{ @orderBy } "
				if @orderByOrder == ASC
					clause += 'asc'
				else
					clause += 'desc'
				end
				clause
			end
		end

		def limitClause
			if @limit
				"limit #{ @limit.begin }, #{ @limit.end }"
			end
		end

		def toSql
			clauses = [ "select #{ fields }", "from #{ tables }" ]
			clauses << whereClause if whereClause
			clauses << orderClause if orderClause
			clauses << limitClause if limitClause
			clauses.join ' '
		end
	end
end

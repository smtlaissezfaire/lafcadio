module Lafcadio
	class Query #:nodoc:
		ASC		= 1
		DESC 	= 2

		attr_reader :objectType, :condition
		attr_accessor :orderBy, :orderByOrder, :limit

		def initialize(objectType, pkIdOrCondition = nil)
			@objectType = objectType
			( @condition, @orderBy, @limit ) = [ nil, nil, nil ]
			if pkIdOrCondition
				if pkIdOrCondition.class <= Condition
					@condition = pkIdOrCondition
				else
					@condition = Query::Equals.new( objectType.sqlPrimaryKeyName,
					                                pkIdOrCondition, objectType )
				end
			end
			@orderByOrder = ASC
		end
		
		def eql?( other ); other.class <= Query && other.toSql == toSql; end

		def fields; '*'; end

		def hash; toSql.hash; end
		
		def limitClause
			"limit #{ @limit.begin }, #{ @limit.end - @limit.begin + 1 }" if @limit
		end

		def orderClause
			if @orderBy
				clause = "order by #{ @orderBy } "
				clause += @orderByOrder == ASC ? 'asc' : 'desc'
				clause
			end
		end

		def sqlPrimaryKeyField(objectType)
			"#{ objectType.tableName }.#{ objectType.sqlPrimaryKeyName }"
		end

		def tables
			concrete_classes = objectType.selfAndConcreteSuperclasses.reverse
			table_names = concrete_classes.collect { |domain_class|
				domain_class.tableName
			}
			table_names.join( ', ' )
		end

		def toSql
			clauses = [ "select #{ fields }", "from #{ tables }" ]
			clauses << whereClause if whereClause
			clauses << orderClause if orderClause
			clauses << limitClause if limitClause
			clauses.join ' '
		end

		def whereClause
			concrete_classes = objectType.selfAndConcreteSuperclasses.reverse
			where_clauses = []
			concrete_classes.each_with_index { |domain_class, i|
				if i < concrete_classes.size - 1
					join_clause = sqlPrimaryKeyField( domain_class ) + ' = ' +
					              sqlPrimaryKeyField( concrete_classes[i+1] )
					where_clauses << join_clause
				else
					where_clauses << @condition.toSql if @condition
				end
			}
			where_clauses.size > 0 ? 'where ' + where_clauses.join( ' and ' ) : nil
		end
	end
end

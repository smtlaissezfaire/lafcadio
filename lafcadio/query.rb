require 'lafcadio/includer'
Includer.include( 'query' )

class Query
	class Inferrer
		def initialize( domainClass, &action )
			@domainClass = domainClass; @action = action
		end
		
		def execute
			impostor = DomainObjectImpostor.new( @domainClass )
			condition = @action.call( impostor )
			query = Query.new( @domainClass, condition )
		end
	end
	
	class DomainObjectImpostor
		attr_reader :domainClass
	
		def initialize( domainClass )
			@domainClass = domainClass
		end
		
		def method_missing( methId, *args )
			fieldName = ( methId.id2name =~ /(.*)=$/ ? $1 : methId.id2name )
			begin
				classField = @domainClass.getField( fieldName )
				ObjectFieldImpostor.new( self, classField )
			rescue MissingError
				super( methId, *args )
			end
		end
		
		def in( fieldName, searchTerms )
			Query::In.new( fieldName, searchTerms, @domainClass )
		end
	end
	
	class ObjectFieldImpostor
		def ObjectFieldImpostor.comparators
			{ 
				'<' => Compare::LESS_THAN, '<=' => Compare::LESS_THAN_OR_EQUAL,
				'>=' => Compare::GREATER_THAN_OR_EQUAL, '>' => Compare::GREATER_THAN
			}
		end
	
		def initialize( domainObjectImpostor, classField )
			@domainObjectImpostor = domainObjectImpostor; @classField = classField
		end
		
		def method_missing( methId, *args )
			methodName = methId.id2name
			if !ObjectFieldImpostor.comparators.keys.index( methodName ).nil?
				registerCompareCondition( methodName, *args )
			else
				super( methId, *args )
			end
		end
		
		def registerCompareCondition( compareStr, searchTerm)
			compareVal = ObjectFieldImpostor.comparators[compareStr]
			Compare.new( @classField.dbFieldName, searchTerm,
			             @domainObjectImpostor.domainClass, compareVal )
		end
		
		def ==( searchTerm )
			Equals.new( @classField.dbFieldName, searchTerm,
			            @domainObjectImpostor.domainClass )
		end
		
		def =~( regexp )
			if regexp.source =~ /^\^(.*)/
				searchTerm = $1
				matchType = Query::Like::POST_ONLY
			elsif regexp.source =~ /(.*)\$$/
				searchTerm = $1
				matchType = Query::Like::PRE_ONLY
			else
				searchTerm = regexp.source
				matchType = Query::Like::PRE_AND_POST
			end
			Query::Like.new( @classField.dbFieldName, searchTerm,
			                 @domainObjectImpostor.domainClass, matchType )
		end
	end
end
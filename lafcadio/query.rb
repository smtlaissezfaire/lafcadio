require 'lafcadio/includer'
Includer.include( 'query' )

class Query
	def self.And( *conditions ); CompoundCondition.new( *conditions ); end
	
	def self.Or( *conditions )
		conditions << CompoundCondition::OR
		CompoundCondition.new( *conditions)
	end

	class DomainObjectImpostor
		attr_reader :domainClass
	
		def initialize( domainClass )
			@domainClass = domainClass
		end
		
		def method_missing( methId, *args )
			fieldName = methId.id2name
			if fieldName == 'objId'
				ObjectFieldImpostor.new( self, fieldName )
			else
				begin
					classField = @domainClass.getField( fieldName )
					ObjectFieldImpostor.new( self, classField )
				rescue MissingError
					super( methId, *args )
				end
			end
		end
	end
	
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
	
	class ObjectFieldImpostor
		def ObjectFieldImpostor.comparators
			{ 
				'lt' => Compare::LESS_THAN, 'lte' => Compare::LESS_THAN_OR_EQUAL,
				'gte' => Compare::GREATER_THAN_OR_EQUAL, 'gt' => Compare::GREATER_THAN
			}
		end
	
		def initialize( domainObjectImpostor, class_field_or_name )
			@domainObjectImpostor = domainObjectImpostor
			if class_field_or_name == 'objId'
				@db_field_name = 'objId'
			else
				@db_field_name = class_field_or_name.dbFieldName
			end
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
			Compare.new( @db_field_name, searchTerm,
			             @domainObjectImpostor.domainClass, compareVal )
		end
		
		def equals( searchTerm )
			Equals.new( @db_field_name, searchTerm,
			            @domainObjectImpostor.domainClass )
		end
		
		def like( regexp )
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
			Query::Like.new( @db_field_name, searchTerm,
			                 @domainObjectImpostor.domainClass, matchType )
		end
		
		def in( *searchTerms )
			Query::In.new( @db_field_name, searchTerms,
			               @domainObjectImpostor.domainClass )
		end
	end
end
require 'lafcadio/includer'
Includer.include( 'query' )

class Query
	class Inferrer
		def initialize( domainClass, &action )
			@domainClass = domainClass; @action = action
		end
		
		def execute
			impostor = DomainObjectImpostor.new( @domainClass )
			@action.call( impostor )
			condition = impostor.getCondition
			query = Query.new( @domainClass, condition )
		end
	end
	
	class DomainObjectImpostor
		attr_reader :domainClass
	
		def initialize( domainClass )
			@domainClass = domainClass
			@conditions = []
		end
		
		def registerCondition( condition )
			@conditions << condition
		end
		
		def getCondition
			@conditions[0]
		end
		
		def getField( fieldName )
			aDomainClass = @domainClass
			field = nil
			while aDomainClass < DomainObject && !field
				field = aDomainClass.getClassField( fieldName )
				aDomainClass = aDomainClass.superclass
			end
			if field
				field
			else
				errStr = "Couldn't find field \"#{ @fieldName }\" in " +
				         "#{ @objectType } domain class"
				raise( MissingError, errStr, caller )
			end
		end
		
		def method_missing( methId, *args )
			classField = getField( methId.id2name )
			if !classField.nil?
				ObjectFieldImpostor.new( self, classField )
			else
				super( methId, *args )
			end
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
			if ObjectFieldImpostor.comparators.keys.index( methodName ).nil?
				super( methId, *args )
			else
				registerCompareCondition( methodName, *args )
			end
		end
		
		def registerCompareCondition( compareStr, searchTerm)
			compareVal = ObjectFieldImpostor.comparators[compareStr]
			condition = Compare.new( @classField.dbFieldName, searchTerm,
			                         @domainObjectImpostor.domainClass,
			                         compareVal )
			@domainObjectImpostor.registerCondition( condition )
		end
	end
end
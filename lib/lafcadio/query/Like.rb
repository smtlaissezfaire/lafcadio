require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		class Like < Condition #:nodoc:
			PRE_AND_POST	= 1
			PRE_ONLY			= 2
			POST_ONLY			= 3

			def initialize(
					fieldName, searchTerm, objectType, matchType = PRE_AND_POST)
				super fieldName, searchTerm, objectType
				@matchType = matchType
			end

			def toSql
				withWildcards = @searchTerm
				if @matchType == PRE_AND_POST
					withWildcards = "%" + withWildcards + "%"
				elsif @matchType == PRE_ONLY
					withWildcards = "%" + withWildcards
				elsif @matchType == POST_ONLY
					withWildcards += "%"
				end
				"#{ dbFieldName } like '#{ withWildcards }'"
			end

			def objectMeets(anObj)
				value = anObj.send @fieldName
				if value.class <= DomainObject || value.class == DomainObjectProxy
					value = value.pkId.to_s
				end
				if value.class <= Array
					(value.index(@searchTerm) != nil)
				else
					if @matchType == PRE_AND_POST
						regexp = Regexp.new(@searchTerm)
					elsif @matchType == PRE_ONLY
						regexp = Regexp.new(@searchTerm.to_s + "$")
					elsif @matchType == POST_ONLY
						regexp = Regexp.new("^" + @searchTerm)
					end
					regexp.match(value) != nil
				end
			end
		end
	end
end

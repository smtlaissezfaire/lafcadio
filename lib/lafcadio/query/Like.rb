require 'lafcadio/query/Condition'

module Lafcadio
	class Query
		# Tests whether a string field is like a string value.
		class Like < Condition
			PRE_AND_POST	= 1
			PRE_ONLY			= 2
			POST_ONLY			= 3

			# [fieldName] The name of the field.
			# [searchTerm] The string that the field will be compared to.
			# [objectType] The domain type we're searching for.
			# [matchType] The type of match we'll accept.
			#             * PRE_AND_POST: Can have extra characters before or after 
			#               the string.
			#             * PRE_ONLY: Can only have extra characters before the 
			#               string.
			#             * POST_ONLY: Can only have extra characters after the 
			#               string.
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
					value = value.objId.to_s
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

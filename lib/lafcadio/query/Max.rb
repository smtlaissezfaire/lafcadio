module Lafcadio
	class Query
		class Max < Query #:nodoc:
			attr_reader :field_name
		
			def initialize( objectType, field_name = 'pkId' )
				super( objectType )
				@field_name = field_name
			end
		
			def collect( coll )
				max = nil
				coll.each { |d_obj|
					a_value = d_obj.send( @field_name )
					max = a_value if max.nil? || a_value > max
				}
				[ max ]
			end
		
			def fields
				"max(#{ @field_name })"
			end
		end
	end
end
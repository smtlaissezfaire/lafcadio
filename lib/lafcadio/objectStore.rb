require 'lafcadio/includer'
Includer.include( 'objectStore' )
require 'lafcadio/util/English'

module Lafcadio
	class ObjectStore
		class MethodDispatch
			attr_reader :symbol, :args
		
			def initialize( orig_method, maybe_proc, *orig_args )
				@orig_method = orig_method
				@maybe_proc = maybe_proc
				@orig_args = orig_args
				@methodName = orig_method.id2name
				if @methodName =~ /^get(.*)$/
					dispatch_get_method
				else
					raise_no_method_error
				end
			end
			
			def dispatch_get_plural_by_query_block
				inferrer = Query::Inferrer.new( @domain_class ) { |obj|
					@maybe_proc.call( obj )
				}
				@symbol = :getSubset
				@args = [ inferrer.execute ]
			end

			def dispatch_get_plural_by_query_block_or_search_term
				searchTerm = @orig_args[0]
				fieldName = @orig_args[1]
				if !@maybe_proc.nil? && searchTerm.nil?
					dispatch_get_plural_by_query_block
				elsif @maybe_proc.nil? && !searchTerm.nil?
					@symbol = :getFiltered
					@args = [ @domain_class.name, searchTerm, fieldName ]
				else
					raise( ArgumentError,
					 	     "Shouldn't send both a query block and a search term",
					       caller )
				end
			end
			
			def dispatch_get_method
				begin
					dispatch_get_singular
				rescue CouldntMatchObjectTypeError
					objectTypeName = English.singular( method_name_after_get )
					begin
						@domain_class = DomainObject.
						                getObjectTypeFromString( objectTypeName )
						dispatch_get_plural_by_query_block_or_search_term
					rescue CouldntMatchObjectTypeError
						raise_no_method_error
					end
				end
			end
			
			def dispatch_get_singular
				objectType = DomainObject.
				             getObjectTypeFromString( method_name_after_get )
				if @orig_args[0].class <= Integer
					@symbol = :get
					@args = [ objectType, @orig_args[0] ]
				elsif @orig_args[0].class <= DomainObject
					@symbol = :getMapObject
					@args = [ objectType, @orig_args[0], @orig_args[1] ]
				end
			end
			
			def method_name_after_get
				@orig_method.id2name =~ /^get(.*)$/
				$1
			end
			
			def raise_no_method_error
				raise( NoMethodError, "undefined method '#{ @methodName }'", caller )
			end
		end
	end
end
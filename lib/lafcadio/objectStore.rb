require 'lafcadio/includer'
Includer.include( 'objectStore' )

module Lafcadio
	class ObjectStore
		class MethodDispatcher
			def initialize( subsystems, methodId, *args )
				@subsystems = subsystems; @methodId = methodId; @args = args
			end
			
			def dispatchGetMethod
				methodName =~ /^get(.*)$/
				objectType = DomainObject.getObjectTypeFromString $1
				if @args[0].class <= Integer
					@subsystems['retriever'].get objectType, @args[0]
				elsif @args[0].class <= DomainObject
					@subsystems['collector'].getMapObject objectType, @args[0], @args[1]
				end
			end
			
			def dispatchToSubsystem
				@resolved = false
				while(@subsystems.size > 0 && !@resolved)
					subsystem = ( @subsystems.shift )[1]
					begin
						@result = subsystem.send methodName, *@args
						@resolved = true
					rescue CouldntMatchObjectTypeError, NoMethodError
						# try the next one
					end
				end
			end
			
			def execute
				begin
					dispatchGetMethod
				rescue CouldntMatchObjectTypeError
					dispatchToSubsystem
					if @resolved
						@result
					else
						raise( NoMethodError, "undefined method '#{ methodName }'",
						       caller )
					end
				end
			end
			
			def methodName; @methodId.id2name; end
		end
	end
end
require 'lafcadio/util'

module Lafcadio
	# A ContextualService is a service that is managed by the Context. 
	# ContextualServices are not instantiated normally. Instead, the instance of 
	# such a service may be retrieved by calling the method
	#   < class name >.get< class name >
	#
	# For example: ObjectStore.getObjectStore
	class ContextualService
		def self.method_missing(methodId)
			methodName = methodId.id2name
			if methodName =~ /^get.*/
				Context.instance.send( methodName, self )
			else
				super methodId
			end
		end

		# The +passKey+ needs to be the Context instance, or else this method fails. 
		# Note that this isn't hard security of any kind; it's simply a gentle 
		# reminder to users of a ContextualService that the class should not be 
		# instantiated directly.
		def initialize(passKey)
			if passKey.class != Context
				raise ArgumentError,
						  "#{ self.class.name.to_s } should only be instantiated by a " +
							  "Context",
						  caller
			end
		end
	end
end
require 'lafcadio/util/Context'

class ContextualService
	def ContextualService.method_missing(methodId)
		methodName = methodId.id2name
		if methodName =~ /^get.*/
			Context.instance.send(methodName)
		else
			super methodId
		end
	end

	def initialize(passKey)
		if passKey.class != Context
			raise ArgumentError,
					"#{ self.class.name.to_s } should only be instantiated by a Context",
					caller
		end
	end
end
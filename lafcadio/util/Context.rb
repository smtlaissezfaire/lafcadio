require 'singleton'
require 'lafcadio/util/ClassUtil'

class Context
	include Singleton

	def initialize
		@resources = {}
	end
	
	def flush
		@resources = {}
	end
	
	def createInstance (resourceName)
		resourceClass = ClassUtil.getClass resourceName
		resourceClass.new self
	end

	def getResource (resourceName)
		resource = @resources[resourceName]
		unless resource
			resource = createInstance resourceName
			setResource resourceName, resource
		end
		resource
	end
	
	def setResource (resourceName, resource)
		@resources[resourceName] = resource
	end

	def method_missing (methId, *args)
		methodName = methId.id2name
		if methodName =~ /^get(.*)$/
			getResource $1
		elsif methodName =~ /^set(.*)$/
			setResource $1, args[0]
		else
			super
		end
	end	
end
require 'singleton'
require 'lafcadio/util/ClassUtil'

# The Context is a singleton object that manages ContextualServices. Each 
# ContextualService is a service that connects in some way to external 
# resources: ObjectStore connects to the database; Emailer connects to SMTP, 
# etc.
#
# Context makes it easy to ensure that each ContextualService is only 
# instantiated once, which can be quite useful for services with expensive 
# creation.
#
# Furthermore, Context allows you to explicitly set instances for a given 
# service, which can be quite useful in testing. For example, once 
# LafcadioTestCase#setup has an instance of MockObjectStore, it calls 
#   context.setObjectStore @mockObjectStore
# which ensures that any future calls to ObjectStore.getObjectStore will return 
# @mockObjectStore, instead of an instance of ObjectStore connecting test code 
# to a live database.
class Context
	include Singleton

	def initialize
		@resources = {}
	end
	
	# Flushes all cached ContextualServices.
	def flush
		@resources = {}
	end
	
	def createInstance(resourceName)
		resourceClass = eval resourceName
		resourceClass.new self
	end

	def getResource(resourceName)
		resource = @resources[resourceName]
		unless resource
			resource = createInstance resourceName
			setResource resourceName, resource
		end
		resource
	end
	
	def setResource(resourceName, resource)
		@resources[resourceName] = resource
	end

	def method_missing(methId, *args)
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
require 'lafcadio/objectStore/ObjectStore'
require 'lafcadio/mock/MockDbBridge'

module Lafcadio
	# Externally, the MockObjectStore looks and acts exactly like the ObjectStore,
	# but stores all its data in memory. This makes it very useful for unit
	# testing, and in fact LafcadioTestCase#setup creates a new instance of
	# MockObjectStore for each test case.
	class MockObjectStore < ObjectStore
		public_class_method :new

		def initialize(context) # :nodoc:
			super(context, MockDbBridge.new)
		end

		def addObject(dbObject) # :nodoc:
			commit dbObject
		end
	end
end
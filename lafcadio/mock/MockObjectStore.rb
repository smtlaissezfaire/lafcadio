require 'lafcadio/objectStore/ObjectStore'
require 'lafcadio/mock/MockDbBridge'

module Lafcadio
	class MockObjectStore < ObjectStore
		public_class_method :new

		def initialize(context)
			super(context, MockDbBridge.new)
		end

		def addObject(dbObject)
			commit dbObject
		end
	end
end
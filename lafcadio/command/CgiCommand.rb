require 'lafcadio/cgi/FieldManager'

class CgiCommand
	attr_reader :message, :success

	def initialize(fieldManager = FieldManager.new)
    @fieldManager = fieldManager
		@objectStore = Context.instance.getObjectStore
		@success = false
		@message = ""
	end
end
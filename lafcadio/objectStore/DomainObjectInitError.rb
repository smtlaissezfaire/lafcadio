module Lafcadio
	class DomainObjectInitError < RuntimeError
		attr_reader :messages

		def initialize(messages)
			@messages = messages
		end
	end
end
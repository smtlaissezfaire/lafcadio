module Lafcadio
	class DomainObjectInitError < RuntimeError #:nodoc:
		attr_reader :messages

		def initialize(messages)
			@messages = messages
		end
	end
end
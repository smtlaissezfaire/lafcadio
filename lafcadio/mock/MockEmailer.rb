class MockEmailer
	attr_reader :messagesSent

	def initialize
		@messagesSent = []
	end
	
	def sendEmail (email)
		@messagesSent << email
	end
end
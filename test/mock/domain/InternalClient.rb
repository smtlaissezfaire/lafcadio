require 'test/mock/domain/Client'

class InternalClient < Client
	def InternalClient.classFields 
		billingType = TextField.new self, 'billingType'
		[ billingType ]
	end
end
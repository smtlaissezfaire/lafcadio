class Email
	HTML_CONTENT_TYPE = 0

	attr_accessor :subject, :toAddress, :fromAddress, :toName, :fromName,
			:contentType, :body, :charSet

	def initialize (subject, toAddress, fromAddress, body = nil)
		@subject = subject
		@toAddress = toAddress
		@fromAddress = fromAddress
		@charSet = 'iso-8859-1'
		@body = body
	end

	def headers
		headers = []
		headers << "Subject: #{@subject}"
		toHeader = "To: "
		if @toName
			toHeader += " #{@toName} <#{@toAddress}>"
		else
			toHeader += " #{@toAddress}"
		end
		headers << toHeader
		fromHeader = "From: "
		if @fromName
			fromHeader += "#{@fromName} <#{@fromAddress}>"
		else
			fromHeader += "#{@fromAddress}"
		end
		headers << fromHeader
		if contentType == HTML_CONTENT_TYPE
			headers << "Content-Type: text/html; charset=\"#{@charset}\""
		end
		headers
	end

	def verifySendable
		nil
	end
end
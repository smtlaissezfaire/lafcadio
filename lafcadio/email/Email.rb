class Email
	HTML_CONTENT_TYPE 			= 0
	MULTIPART_CONTENT_TYPE 	= 1

	attr_accessor :subject, :toAddress, :fromAddress, :toName, :fromName,
			:contentType, :body, :charSet

	# Unless they are explicitly set using accessors, the following defaults 
	# apply:
	# [toName] nil
	# [fromName] nil
	# [contentType] nil
	# [charSet] 'iso-8859-1'
	def initialize(subject, toAddress, fromAddress, body = nil)
		@subject = subject
		@toAddress = toAddress
		@fromAddress = fromAddress
		@charSet = 'iso-8859-1'
		@body = body
	end

	# Returns an array of strings describing the headers for this email message.
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
			headers << "Content-Type: text/html; charset=\"#{@charSet}\""
			headers << "MIME-Version: 1.0"
		elsif contentType == MULTIPART_CONTENT_TYPE
			headers << "Content-Type: Multipart/Alternative; charset=\"#{@charSet}\""
			headers << "MIME-Version: 1.0"
		end
		headers
	end

	# Emailer calls this before sending a message; subclasses can override this if 
	# they want to ensure that certain parts of the message are valid before 
	# sending.
	def verifySendable
		nil
	end
end
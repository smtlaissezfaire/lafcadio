require 'cgi'

class CgiUtil
	def CgiUtil.cgiArgString(hash)
		cgiKeyValuePairs = []
		hash.each { |key, value|
			cgiKeyValuePairs << "#{ key }=#{ CGI.escape(value) }" if value
		}
		cgiKeyValuePairs.join "&"
	end
end

require 'cgi'

class CgiUtil
	# Turns a hash into a string suitable for use as a CGI argument.
	def CgiUtil.cgiArgString(hash)
		cgiKeyValuePairs = []
		hash.each { |key, value|
			cgiKeyValuePairs << "#{ key }=#{ CGI.escape(value) }" if value
		}
		cgiKeyValuePairs.join "&"
	end
end

class HTML < Array
	class JSIfElseTree < Array
  	def addPair (condition, statements)
    	self << [ condition, statements ]
	  end

  	def toJavaScript
    	js = ""
	    self.each { |pair|
  	    condition = pair[0]
    	  statement = pair[1]
      	if js == ""
					js += "if (#{condition}) {\n"
	      else
					js += "} else if (#{condition}) {\n"
	      end
  	    js += "  #{statement}\n"
    	}
	    js += "}"
  	  js
		end
  end
end
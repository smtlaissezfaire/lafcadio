# A collection of utilities for dealing with Strings.
class StrUtil
	# Returns the number of times that <tt>regexp</tt> occurs in <tt>str</tt>.
	def StrUtil.countOccurrences(str, regexp)
		count = 0
		while str =~ regexp
			count += 1
			str = $'
		end
		count
	end

	# Returns a string that represents <tt>floatValue</tt> to <tt>precision</tt> 
	# decimal places, rounding <tt>floatValue</tt> down if necessary. If 
	# <tt>padDecimals</tt> is set to <tt>false</tt> and <tt>floatValue</tt> rounds 
	# to a whole number, there will be no decimals shown.
	#
	#   StrUtil.floatFormat(24.55, 3)      -> "24.550"
	#   StrUtil.floatFormat(24.55, 0)      -> "24"
	#   StrUtil.floatFormat(100, 2, false) -> "100"
  def StrUtil.floatFormat(floatValue, precision, padDecimals = true)
    str = floatValue.floor.to_s
    if precision > 0
      decimal = floatValue - floatValue.floor
      decimalStr =(decimal * 10 ** precision).floor.to_s
      if decimalStr.size < precision
        decimalStr += "0" *(precision - decimalStr.size)
      end
      if padDecimals || decimalStr =~ /[123456789]/
	      str += "."
  	    str += decimalStr
  	  end
    end
    str
  end

	# Returns a float <tt>value</tt> formatted to two decimal places and preceded 
	# by a "$".
	def StrUtil.moneyFormat(value)
		"$#{floatFormat value, 2}"
	end

	# Increments a filename. If the filename ends with a number, it increments 
	# that number; otherwise it appends a "_1" after the filename but before the 
	# file extension.
	#
	#   StrUtil.incrementFilename("john.jpg")   -> "john_1.jpg"
	#   StrUtil.incrementFilename("john_1.jpg") -> "john_2.jpg"
	#   StrUtil.incrementFilename("john_2.jpg") -> "john_3.jpg"
  def StrUtil.incrementFilename(filename)
    extension = filename.split(/\./).last
    filename.sub!(/\..*$/, '')
    if filename =~ /_(\d*)$/
      newSuffix = $1.to_i + 1
      filename = $` + "_#{newSuffix}"
    else
      filename += "_1"
    end
    filename += ".#{extension}"
    filename
  end

	# Decapitalizes the first letter of <tt>string</tt>, or decapitalizes the 
	# entire string if it's all capitals.
	#
	#   StrUtil.decapitalize('InternalClient') -> "internalClient"
	#   StrUtil.decapitalize('SKU')            -> "sku"
	def StrUtil.decapitalize(string)
		firstLetter = string[0..0].downcase
		string = firstLetter + string[1..string.length]
		newString = ""
		while string =~ /([A-Z])([^a-z]|$)/
			newString += $`
			newString += $1.downcase
			string = $2 + $'
		end
		newString += string
		newString
	end

	def StrUtil.pad(string, size, fillChar)
		while string.length < size
			string = fillChar + string
		end
		string
	end

	def StrUtil.numericStringToUsFormat(numericString)
		numericString.gsub!(/,/, '.') if numericString =~ /,\d{2}$/
		numericString
	end

	# Divides <tt>string</tt> into substrings using <tt>regexp</tt> as a 
	# delimiter, and returns an array containing both the substrings and the 
	# portions that matched <tt>regexp</tt>.
	#
	#   StrUtil.splitKeepInBetweens('theZquickZZbrownZfox', /Z+/) ->
	#     ['the', 'Z', 'quick', 'ZZ', 'brown', 'Z', 'fox' ]
	def StrUtil.splitKeepInBetweens(string, regexp)
		result = []
		while string =~ regexp
			result << $`
			result << $&
			string = $'
		end
		result << string unless string == ''
		result
	end
	
	# Breaks <tt>string</tt> into lines no longer than <tt>lineLength</tt>.
	#
	#   StrUtil.lineWrap('the quick brown fox jumped over the lazy dog.') ->
	#     "the quick\nbrown fox\njumped\nover the\nlazy dog."
	def StrUtil.lineWrap(string, lineLength)
		words = string.split ' '
		line = ''
		lines = []
		words.each { |word|
			if line.length + word.length + 1 > lineLength
				lines << line
				line = ''
			end
			line = line != '' ? "#{ line } #{ word }" : word
		}
		lines << line
		lines.join "\n"
	end
end

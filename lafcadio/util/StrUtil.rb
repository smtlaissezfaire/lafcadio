class StrUtil
	def StrUtil.countOccurrences(str, regexp)
		count = 0
		while str =~ regexp
			count += 1
			str = $'
		end
		count
	end

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

	def StrUtil.moneyFormat(value)
		"$#{floatFormat value, 2}"
	end

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

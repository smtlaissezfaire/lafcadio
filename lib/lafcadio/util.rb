require 'lafcadio/includer'
Includer.include( 'util' )

class Array
	# If this array has one element, returns that element; otherwise, raises an
	# error.
	def only
		if size != 1
			raise "Expected single-value Array but Array has #{ size } members"
		else
			first
		end
	end
end

class Class < Module
	# Given a String, returns a class object by the same name.
	def self.getClass(className)
		theClass = nil
		ObjectSpace.each_object(Class) { |aClass|
			theClass = aClass if aClass.name == className
		}
		if theClass
			theClass
		else
			raise( Lafcadio::MissingError, "Couldn't find class \"#{ className }\"",
			       caller )
		end
	end
	
	# Returns the name of <tt>aClass</tt> itself, stripping off the names of any 
	# containing modules or outer classes.
	def bareName
		name =~ /::/
		$' || name
	end
end

module Lafcadio
	class MissingError < RuntimeError
	end
end

class Numeric
	# Returns a string that represents the numbeer to <tt>precision</tt> decimal 
	# places, rounding down if necessary. If <tt>padDecimals</tt> is set to 
	# <tt>false</tt> and the number rounds to a whole number, there will be no 
	# decimals shown.
	#
	#   (24.55).precisionFormat( 3 )    -> "24.550"
	#   (24.55).precisionFormat( 0 )    -> "24"
	#   100.precisionFormat( 2, false ) -> "100"
  def precisionFormat(precision, padDecimals = true)
    str = floor.to_s
    if precision > 0
      decimal = self - self.floor
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
end

class String
	# Returns the number of times that <tt>regexp</tt> occurs in the string.
	def countOccurrences(regexp)
		count = 0
		str = self.clone
		while str =~ regexp
			count += 1
			str = $'
		end
		count
	end
	
	# Decapitalizes the first letter of the string, or decapitalizes the 
	# entire string if it's all capitals.
	#
	#   'InternalClient'.decapitalize -> "internalClient"
	#   'SKU'.decapitalize            -> "sku"
	def decapitalize
		string = clone
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

	# Increments a filename. If the filename ends with a number, it increments 
	# that number; otherwise it appends a "_1" after the filename but before the 
	# file extension.
	#
	#   "john.jpg".incrementFilename   -> "john_1.jpg"
	#   "john_1.jpg".incrementFilename -> "john_2.jpg"
	#   "john_2.jpg".incrementFilename -> "john_3.jpg"
  def incrementFilename
		filename = self.clone
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

	# Breaks a string into lines no longer than <tt>lineLength</tt>.
	#
	#   'the quick brown fox jumped over the lazy dog.'.lineWrap( 10 ) ->
	#     "the quick\nbrown fox\njumped\nover the\nlazy dog."
	def lineWrap(lineLength)
		words = split ' '
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
	
	# Turns a numeric string into U.S. format if it's not already formatted that
	# way.
	#
	#   "10,00".numericStringToUsFormat -> "10.00"
	#   "10.00".numericStringToUsFormat -> "10.00"
	def numericStringToUsFormat
		numericString = clone
		numericString.gsub!(/,/, '.') if numericString =~ /,\d{2}$/
		numericString
	end

	# Left-pads a string with +fillChar+ up to +size+ size.
	#
	#   "a".pad( 10, "+") -> "+++++++++a"
	def pad(size, fillChar)
		string = clone
		while string.length < size
			string = fillChar + string
		end
		string
	end
	
	# Divides a string into substrings using <tt>regexp</tt> as a 
	# delimiter, and returns an array containing both the substrings and the 
	# portions that matched <tt>regexp</tt>.
	#
	#   'theZquickZZbrownZfox'.splitKeepInBetweens(/Z+/) ->
	#     ['the', 'Z', 'quick', 'ZZ', 'brown', 'Z', 'fox' ]
	def splitKeepInBetweens(regexp)
		result = []
		string = clone
		while string =~ regexp
			result << $`
			result << $&
			string = $'
		end
		result << string unless string == ''
		result
	end
end
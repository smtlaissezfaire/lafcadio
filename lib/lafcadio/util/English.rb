module Lafcadio
	# A collection of English-language specific utility methods.
	class English
		# Turns a camel-case string ("camelCaseToEnglish") to plain English ("camel 
		# case to english"). Each word is decapitalized.
		def self.camelCaseToEnglish(camelCaseStr)
			words = []
			nextCapIndex =(camelCaseStr =~ /[A-Z]/)
			while nextCapIndex != nil
				words << $` if $`.size > 0
				camelCaseStr = $& + $'
				camelCaseStr[0] = camelCaseStr[0..0].downcase
				nextCapIndex =(camelCaseStr =~ /[A-Z]/)
			end
			words << camelCaseStr
			words.join ' '
		end

		# Turns an English language string into camel case.
		def self.englishToCamelCase(englishStr)
			cc = ""
			englishStr.split.each { |word|
				word = word.capitalize unless cc == ''
				cc = cc += word
			}
			cc
		end

		# Given a singular noun, returns the plural form.
		def self.plural(singular)
			consonantYPattern = Regexp.new("([^aeiou])y$", Regexp::IGNORECASE)
			if singular =~ consonantYPattern
				singular.gsub consonantYPattern, '\1ies'
			elsif singular =~ /[xs]$/
				singular + "es"
			else
				singular + "s"
			end
		end

		# Returns the proper noun form of a string by capitalizing most of the 
		# words.
		#
		# Examples:
		#   English.properNoun("bosnia and herzegovina") ->
		#     "Bosnia and Herzegovina"
		#   English.properNoun("macedonia, the former yugoslav republic of") ->
		#     "Macedonia, the Former Yugoslav Republic of"
		#   English.properNoun("virgin islands, u.s.") ->
		#     "Virgin Islands, U.S."
		def self.properNoun(string)
			properNoun = ""
			while(matchIndex = string =~ /[\. ]/)
				word = string[0..matchIndex-1]
				word = word.capitalize unless [ 'and', 'the', 'of' ].index(word) != nil
				properNoun += word + $&
				string = string[matchIndex+1..string.length]
			end
			word = string
			word = word.capitalize unless [ 'and', 'the', 'of' ].index(word) != nil
			properNoun += word
			properNoun
		end

		# Given a format for a template sentence, generates the sentence while 
		# accounting for details such as pluralization and whether to use "a" or 
		# "an".
		# [format] The format string. Format codes are:
		#          * %num: Number
		#          * %is: Transitive verb. This will be turned into "is" or "are", 
		#            depending on <tt>number</tt>.
		#          * %nam: Name. This will be rendered as either singular or 
		#            plural, depending on <tt>number</tt>.
		#          * %a: Indefinite article. This will be turned into "a" or "an", 
		#            depending on <tt>name</tt>.
		# [name] The name of the object being described.
		# [number] The number of the objects being describes.
		#
		# Examples:
		#   English.sentence("There %is currently %num %nam", "product category",
		#                        0) -> "There are currently 0 product categories"
		#   English.sentence("There %is currently %num %nam", "product category",
		#                        1) -> "There is currently 1 product category"
		#   English.sentence("Add %a %nam", "invoice") -> "Add an invoice"	
		def self.sentence(format, name, number = 1)
			sentence = format
			sentence.gsub!( /%num/, number.to_s )
			isVerb = number == 1 ? "is" : "are"
			sentence.gsub!( /%is/, isVerb )
			name = English.plural name if number != 1
			sentence.gsub!( /%nam/, name )
			article = startsWithVowelSound(name) ? 'an' : 'a'
			sentence.gsub!( /%a/, article )
			sentence
		end
		
		def self.singular(plural)
			if plural =~ /(.*)ies/
				$1 + 'y'
			elsif plural =~ /(.*s)es/
				$1
			else
				plural =~ /(.*)s/
				$1
			end
		end
		
		# Does this word start with a vowel sound? "User" and "usury" don't, but 
		# "ugly" does.
		def self.startsWithVowelSound(word)
			uSomethingUMatch = word =~ /^u[^aeiuo][aeiou]/
			# 'user' and 'usury' don't start with a vowel sound
			word =~ /^[aeiou]/ && !uSomethingUMatch
		end
	end
end
class EnglishUtil
  def EnglishUtil.camelCaseToEnglish(camelCaseStr)
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

  def EnglishUtil.sentence(format, name, number = 1)
    sentence = format
    sentence.gsub! /%num/, number.to_s
    isVerb = number == 1 ? "is" : "are"
    sentence.gsub! /%is/, isVerb
    name = EnglishUtil.plural name if number != 1
    sentence.gsub! /%nam/, name
		article = startsWithVowelSound(name) ? 'an' : 'a'
		sentence.gsub! /%a/, article
    sentence
  end

	def EnglishUtil.startsWithVowelSound(word)
		uSomethingUMatch = word =~ /^u[^aeiuo][aeiou]/
				# 'user' and 'usury' don't start with a vowel sound
		word =~ /^[aeiou]/ && !uSomethingUMatch
	end

  def EnglishUtil.plural(singular)
    consonantYPattern = Regexp.new("([^aeiou])y$", Regexp::IGNORECASE)
    if singular =~ consonantYPattern
			singular.gsub consonantYPattern, '\1ies'
    elsif singular =~ /[xs]$/
			singular + "es"
		else
			singular + "s"
    end
  end

	def EnglishUtil.properNoun(string)
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

	def EnglishUtil.singular(plural)
		if plural =~ /(.*)ies/
			$1 + 'y'
		elsif plural =~ /(.*s)es/
			$1
		else
			plural =~ /(.*)s/
			$1
		end
	end

	def EnglishUtil.englishToCamelCase(englishStr)
		cc = ""
		englishStr.split.each { |word|
			word = word.capitalize unless cc == ''
			cc = cc += word
		}
		cc
	end
end

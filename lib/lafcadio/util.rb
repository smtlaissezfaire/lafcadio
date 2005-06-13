require 'delegate'
require 'lafcadio/depend'
require 'singleton'

module Lafcadio
	# The Context is a singleton object that manages ContextualServices. Each 
	# ContextualService is a service that connects in some way to external 
	# resources: ObjectStore connects to the database; Emailer connects to SMTP, 
	# etc.
	#
	# Context makes it easy to ensure that each ContextualService is only 
	# instantiated once, which can be quite useful for services with expensive 
	# creation.
	#
	# Furthermore, Context allows you to explicitly set instances for a given 
	# service, which can be quite useful in testing. For example, once 
	# LafcadioTestCase#setup has an instance of MockObjectStore, it calls 
	#   context.setObjectStore @mockObjectStore
	# which ensures that any future calls to ObjectStore.getObjectStore will 
	# return @mockObjectStore, instead of an instance of ObjectStore connecting 
	# test code to a live database.
	class Context
		include Singleton

		def initialize
			flush
			@init_procs = {}
		end
		
		def create_instance( service_class, *init_args ) #:nodoc:
			if ( proc = @init_procs[service_class] )
				proc.call( *init_args )
			else
				service_class.new( *init_args )
			end
		end
		
		# Flushes all cached ContextualServices.
		def flush
			@resources_by_class = Hash.new { |hash, key| hash[key] = {} }
		end

		def get_resource( service_class, *init_args ) #:nodoc:
			resource = @resources_by_class[service_class][init_args]
			unless resource
				resource = create_instance( service_class, *init_args )
				set_resource( service_class, resource, *init_args )
			end
			resource
		end
		
		def set_init_proc( service_class, proc )
			@init_procs[service_class] = proc
		end
		
		def set_resource( service_class, resource, *init_args ) #:nodoc:
			@resources_by_class[service_class][init_args] = resource
		end
	end

	# A ContextualService is a service that is managed by the Context. 
	# ContextualServices are not instantiated normally. Instead, the instance of 
	# such a service may be retrieved by calling the method
	#   < class name >.get< class name >
	#
	# For example: ObjectStore.getObjectStore
	class ContextualService
		def self.flush; Context.instance.set_resource( self, nil ); end

		def self.method_missing( symbol, *args )
			method_name = symbol.id2name
			target = nil
			if method_name =~ /^get_(.*)/
				target = :get_resource if $1.underscore_to_camel_case == basename
			elsif method_name =~ /^set_(.*)/
				target = :set_resource if $1.underscore_to_camel_case == basename
			end
			if target
				Context.instance.send( target, self, *args )
			else
				super
			end
		end

		def self.set_init_proc
			proc = proc { yield }
			Context.instance.set_init_proc( self, proc )
		end

		# ContextualServices can only be initialized through the Context instance.
		# Note that if you're writing your own initialize method in a child class,
		# you should make sure to call super() or you'll overwrite this behavior.
		def initialize
			regexp = %r{lafcadio/util\.rb.*create_instance}
			unless caller.any? { |line| line =~ regexp }
				raise ArgumentError,
				"#{ self.class.name.to_s } should be instantiated by calling " +
				    self.class.name.to_s + ".get_" + self.class.name.camel_case_to_underscore,
				caller
			end
		end
	end

	# A collection of English-language specific utility methods.
	class English
		# Turns a camel-case string ("camel_case_to_english") to plain English ("camel 
		# case to english"). Each word is decapitalized.
		def self.camel_case_to_english(camelCaseStr)
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
		def self.english_to_camel_case(englishStr)
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
			elsif singular =~ /^(.*)xis$/
				$1 + 'xes'
			elsif singular =~ /[xs]$/
				singular + "es"
			elsif singular =~ /(.*)tum$/
				$1 + 'ta'
			else
				singular + "s"
			end		end

		# Returns the proper noun form of a string by capitalizing most of the 
		# words.
		#
		# Examples:
		#   English.proper_noun("bosnia and herzegovina") ->
		#     "Bosnia and Herzegovina"
		#   English.proper_noun("macedonia, the former yugoslav republic of") ->
		#     "Macedonia, the Former Yugoslav Republic of"
		#   English.proper_noun("virgin islands, u.s.") ->
		#     "Virgin Islands, U.S."
		def self.proper_noun(string)
			proper_noun = ""
			while(matchIndex = string =~ /[\. ]/)
				word = string[0..matchIndex-1]
				word = word.capitalize unless [ 'and', 'the', 'of' ].index(word) != nil
				proper_noun += word + $&
				string = string[matchIndex+1..string.length]
			end
			word = string
			word = word.capitalize unless [ 'and', 'the', 'of' ].index(word) != nil
			proper_noun += word
			proper_noun
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
			article = starts_with_vowel_sound(name) ? 'an' : 'a'
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
		def self.starts_with_vowel_sound(word)
			uSomethingUMatch = word =~ /^u[^aeiuo][aeiou]/
			# 'user' and 'usury' don't start with a vowel sound
			word =~ /^[aeiou]/ && !uSomethingUMatch
		end
	end

	# LafcadioConfig is a Hash that takes its data from the config file. You'll 
	# have to set the location of that file before using it: Use 
	# LafcadioConfig.set_filename.
	#
	# LafcadioConfig expects its data to be colon-delimited, one key-value pair 
	# to a line. For example:
	#   dbuser:user
	#   dbpassword:password
	#   dbname:lafcadio_test
	#   dbhost:localhost
	class LafcadioConfig < Hash
		@@value_hash = nil
	
		def self.set_filename(filename); @@filename = filename; end
		
		def self.set_values( value_hash ); @@value_hash = value_hash; end

		def initialize
			if @@value_hash
				@@value_hash.each { |key, value| self[key] = value }
			else
				File.new( @@filename ).each_line { |line|
					line.chomp =~ /^(.*?):(.*)$/
					self[$1] = $2
				}
			end
		end
	end

	class MissingError < RuntimeError
	end
end

class String
	# Returns the underscored version of a camel-case string.
	def camel_case_to_underscore
		( gsub( /(.)([A-Z])/ ) { $1 + '_' + $2.downcase } ).downcase
	end

	# Returns the number of times that <tt>regexp</tt> occurs in the string.
	def count_occurrences(regexp)
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
	
	# Returns the camel-case equivalent of an underscore-style string.
	def underscore_to_camel_case
		capitalize.gsub( /_([a-zA-Z0-9]+)/ ) { |s| s[1,s.size - 1].capitalize }
	end
end
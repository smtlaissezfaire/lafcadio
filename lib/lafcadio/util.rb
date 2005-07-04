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
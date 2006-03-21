require 'delegate'
require 'lafcadio/depend'
require 'singleton'

module Lafcadio	
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
	#   dbtype:Mysql ("Mysql" is the default; select "Pg" for Postgres)
	class LafcadioConfig < Hash
		@@value_hash = {}
		@@instances = []
		
		def self.[]=( k, v )
			@@value_hash[k] = v
			@@instances.each do |instance| instance[k] = v; end
		end
		
		def self.new
			inst = super
			@@instances << inst
			inst
		end
	
		def self.set_filename(filename)
			@@value_hash = {}
			if filename
				File.new( filename ).each_line { |line|
					line.chomp =~ /^(.*?):(.*)$/
					self[$1] = $2
				}
			end
		end
		
		def self.set_values( value_hash )
			@@value_hash = ( value_hash.nil? ? {} : value_hash )
			ObjectStore.db_type = @@value_hash['dbtype'] if @@value_hash['dbtype']
		end

		def initialize
			@@value_hash.each { |key, value| self[key] = value }
		end
	end

	class MissingError < RuntimeError; end
end

class String
	unless method_defined?( :camel_case_to_underscore )

		# Returns the underscored version of a camel-case string.
		def camel_case_to_underscore
			( gsub( /(.)([A-Z])/ ) { $1 + '_' + $2.downcase } ).downcase
		end
		
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
	
	unless method_defined?( :underscore_to_camel_case )

		# Returns the camel-case equivalent of an underscore-style string.
		def underscore_to_camel_case
			capitalize.gsub( /_([a-zA-Z0-9]+)/ ) { |s| s[1,s.size - 1].capitalize }
		end
	
	end
end
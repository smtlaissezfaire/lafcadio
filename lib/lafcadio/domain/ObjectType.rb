require 'lafcadio/domain'
require 'lafcadio/util'

module Lafcadio
	# A utility class that handles a few details for the DomainObject class. All 
	# the methods here are usually called as methods of DomainObject, and then 
	# delegated to this class.
	class ObjectType
		@@instances = {}
		
		def self.flush #:nodoc:
			@@instances = {}
		end
		
		def self.getObjectType( aClass ) #:nodoc:
			instance = @@instances[aClass]
			if instance.nil?
				@@instances[aClass] = new( aClass )
				instance = @@instances[aClass]
			end
			instance
		end

		private_class_method :new

		def initialize(objectType) #:nodoc:
			@objectType = objectType
			( @classFields, @xmlParser, @tableName ) = [ nil, nil, nil ]
		end

		# Returns an Array of ObjectField instances for this domain class, parsing
		# them from XML if necessary.
		def getClassFields
			unless @classFields
				try_load_xml_parser
				if @xmlParser
					@classFields = @xmlParser.getClassFields
				else
					error_msg = "Couldn't find either an XML class description file " +
											"or getClassFields method for " + @objectType.name
					raise MissingError, error_msg, caller
				end
			end
			@classFields
		end

		# Returns the name of the primary key in the database, retrieving it from
		# the class definition XML if necessary.
		def sqlPrimaryKeyName( set_sql_primary_key_name = nil )
			if set_sql_primary_key_name
				@sqlPrimaryKeyName = set_sql_primary_key_name
			elsif @sqlPrimaryKeyName
				@sqlPrimaryKeyName
			else
				try_load_xml_parser
				if !@xmlParser.nil? && ( spkn = @xmlParser.sqlPrimaryKeyName )
					spkn
				else
					'pkId'
				end
			end
		end

		# Returns the table name, which is assumed to be the domain class name 
		# pluralized, and with the first letter lowercase. A User class is
		# assumed to be stored in a "users" table, while a ProductCategory class is
		# assumed to be stored in a "productCategories" table.
		def tableName( set_table_name = nil )
			if set_table_name
				@tableName = set_table_name
			elsif @tableName
				@tableName
			else
				try_load_xml_parser
				if (!@xmlParser.nil? && tableName = @xmlParser.tableName)
					tableName
				else
					tableName = @objectType.bareName
					tableName[0] = tableName[0..0].downcase
					English.plural tableName
				end
			end
		end
		
		def try_load_xml_parser
			dirName = LafcadioConfig.new['classDefinitionDir']
			xmlFileName = @objectType.bareName + '.xml'
			xmlPath = File.join( dirName, xmlFileName )
			xml = ''
			begin
				File.open( xmlPath ) { |file| xml = file.readlines.join }
				@xmlParser = ClassDefinitionXmlParser.new( @objectType, xml )
			rescue Errno::ENOENT
				# no xml file, so no @xmlParser
			end
		end
	end
end
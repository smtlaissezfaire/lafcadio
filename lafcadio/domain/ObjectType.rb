require 'lafcadio/domain'
require 'lafcadio/util'

# A utility class that handles a few details for the DomainObject class. All the 
# methods here are usually called as methods of DomainObject, and then delegated 
# to this class.
class ObjectType
	@@instances = {}
	
	def self.flush; @@instances = {}; end
	
	def self.getObjectType( aClass )
		instance = @@instances[aClass]
		if instance.nil?
			@@instances[aClass] = new( aClass )
			instance = @@instances[aClass]
		end
		instance
	end

	private_class_method :new

	def initialize(objectType)
		@objectType = objectType
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

  def getClassFields
		unless @classFields
			if @xmlParser
				@classFields = @xmlParser.getClassFields
			else
				error_msg = "Couldn't find either an XML class description file or " +
										"getClassFields method for " + @objectType.name
				raise MissingError, error_msg, caller
			end
		end
		@classFields
  end

	def sqlPrimaryKeyName
		!@xmlParser.nil? && ( spkn = @xmlParser.sqlPrimaryKeyName ) ? spkn : 'objId'
	end

	# Returns the table name, which is assumed to be the domain class name 
	# pluralized, and with the first letter lowercase. A User class is
	# assumed to be stored in a "users" table, while a ProductCategory class is
	# assumed to be stored in a "productCategories" table.
	def tableName
		if (!@xmlParser.nil? && tableName = @xmlParser.tableName)
			tableName
		else
			tableName = @objectType.bareName
			tableName[0] = tableName[0..0].downcase
			English.plural tableName
		end
	end
end


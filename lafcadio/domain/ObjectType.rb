# A utility class that handles a few details for the DomainObject class. All the 
# methods here are usually called as methods of DomainObject, and then delegated 
# to this class.
class ObjectType
	@@instances = {}
	
	def ObjectType.getObjectType( aClass )
		instance = @@instances[aClass]
		if instance.nil?
			@@instances[aClass] = new( aClass )
			instance = @@instances[aClass]
		end
		instance
	end

	private_class_method :new

	def initialize(objectType)
		require 'lafcadio/domain'

		@objectType = objectType
		dirName = LafcadioConfig.new['classDefinitionDir']
		xmlFileName = ClassUtil.bareClassName( @objectType ) + '.xml'
		xmlPath = File.join( dirName, xmlFileName )
		xml = ''
		File.open( xmlPath ) { |file| xml = file.readlines.join }
		@xmlParser = ClassDefinitionXmlParser.new( @objectType, xml )
	end

	# Returns the table name, which is assumed to be the domain class name 
	# pluralized, and with the first letter lowercase. A User class is
	# assumed to be stored in a "users" table, while a ProductCategory class is
	# assumed to be stored in a "productCategories" table.
	def tableName
		if (tableName = @xmlParser.tableName)
			tableName
		else
			tableName = ClassUtil.bareClassName @objectType
			tableName[0] = tableName[0..0].downcase
			EnglishUtil.plural tableName
		end
	end

	def sqlPrimaryKeyName
		@xmlParser.sqlPrimaryKeyName || 'objId'
	end

  def englishName
		EnglishUtil.camelCaseToEnglish ClassUtil.bareClassName(@objectType)
  end
  
  def getClassFields
		unless @classFields
			@classFields = @xmlParser.getClassFields
		end
		@classFields
  end
end


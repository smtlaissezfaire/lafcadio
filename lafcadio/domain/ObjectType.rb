# A utility class that handles a few details for the DomainObject class. All the 
# methods here are usually called as methods of DomainObject, and then delegated 
# to this class.
class ObjectType
	def initialize(objectType)
		@objectType = objectType
	end

	# Returns the table name, which is assumed to be the domain class name 
	# pluralized, and with the first letter lowercase. A User class is
	# assumed to be stored in a "users" table, while a ProductCategory class is
	# assumed to be stored in a "productCategories" table.
	def tableName
		tableName = ClassUtil.bareClassName @objectType
		tableName[0] = tableName[0..0].downcase
		EnglishUtil.plural tableName
	end

  def englishName
		EnglishUtil.camelCaseToEnglish ClassUtil.bareClassName(@objectType)
  end
end


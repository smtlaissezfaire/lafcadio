class ObjectType
	def initialize (objectType)
		@objectType = objectType
	end

	def tableName
		tableName = ClassUtil.bareClassName @objectType
		tableName[0] = tableName[0..0].downcase
		EnglishUtil.plural tableName
	end

  def englishName
		EnglishUtil.camelCaseToEnglish ClassUtil.bareClassName(@objectType)
  end
end


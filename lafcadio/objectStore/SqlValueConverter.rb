require 'lafcadio/util/ClassUtil'

class SqlValueConverter
  attr_reader :objectType, :rowHash

  def initialize (objectType, rowHash)
    @objectType = objectType
    @rowHash = rowHash
  end

  def execute
		require 'lafcadio/objectField/LinkField'
    objectHash = {}
    objectHash["objId"] = rowHash[@objectType.sqlPrimaryKeyName].to_i
		objectType.selfAndConcreteSuperclasses.each { |anObjectType|
	    anObjectType.classFields.each { |field|
				key = field.name
    	  stringValue = rowHash[field.dbFieldName]
      	obj = field.valueFromSQL stringValue
	      objectHash[key] = obj
  	  }
		}
    objectHash
  end
end


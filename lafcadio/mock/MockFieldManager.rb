require 'tempfile'
require 'lafcadio/util/HashOfArrays'
require 'lafcadio/cgi/FieldManager'
require 'lafcadio/objectField/ImageField'

class MockFieldManager < FieldManager
  def initialize (initHash = {})
		@valueHash = HashOfArrays.new
    @imageFields = []
    objTypeString = initHash["objectType"]
    if objTypeString != nil
      objTypeString = objTypeString.read if objTypeString.type == Tempfile
      @objectType = ClassUtil.getObjectTypeFromString objTypeString
      @objectType.classFields.each { |field|
        @imageFields << field.name if field.type == ImageField
      }
    end
    initHash.keys.each { |key|
			value = initHash[key]
			if value.type == Tempfile
#	      value = processTempfile(value, key)
			elsif value.type <= Numeric
				value = value.to_s
			end
			value = [value] unless value.type == Array
			@valueHash.set(key, value)
    }
		if (objectTypeString = get('objectType'))
			@objectType = ClassUtil.getObjectTypeFromString objectTypeString
		end
  end
end

require 'lafcadio/util/EnglishUtil'
require 'lafcadio/objectField/FieldViewer'
require 'lafcadio/objectField/FieldValueError'

class ObjectField
	include Comparable

  attr_reader :name, :defaultFieldName, :objectType
  attr_accessor :notNull, :hideLabel, :writeOnce, :unique, :hideDisplay,
      :default, :dbFieldName, :notUniqueMsg

  def ObjectField.valueType
    Object
  end

  def ObjectField.viewerType
    FieldViewer
  end

	# [objectType] The domain class that this object field belongs to.
	# [name] The name of this field.
	# [englishName] The descriptive English name of this field.
  def initialize(objectType, name, englishName = nil)
    @objectType = objectType
    @name = name
    @dbFieldName = name
    @notNull = true
    @unique = false
    @default = nil
  end
  
  def englishName
		EnglishUtil.camelCaseToEnglish(name).capitalize
  end

  def nullErrorMsg
		EnglishUtil.sentence "Please enter %a %nam.", englishName.downcase
  end

  def verify(value, objId)
    if !value && notNull
      raise FieldValueError, nullErrorMsg, caller
    end
    if value
      valueType = self.class.valueType
			unless value.class <= valueType
        raise FieldValueError, 
						"#{name} needs an object of type #{valueType.name}", caller
      end
      verifyUniqueness(value, objId) if unique
    end
  end

  def verifyUniqueness(value, objId)
    collection = ObjectStore.getObjectStore.getAll(@objectType)
    collisions = collection.filterObjects(self.name, value)
    collisions = collisions.removeObjects("objId", objId)
    if collisions.size > 0
			if @notUniqueMsg
				notUniqueMsg = @notUniqueMsg
			else
				notUniqueMsg = "That #{englishName.downcase} is already taken. " +
						"Please choose another."
			end
      raise FieldValueError, notUniqueMsg, caller
    end
  end

	# Returns the name that this field is referenced by in the MySQL table. By 
	# default this is the same as the name; to override it, set 
	# ObjectField#dbFieldName.
  def nameForSQL
    dbFieldName
  end

	# Returns a string value suitable for committing this field's value to MySQL.
  def valueForSQL(value)
    value || 'null'
  end

  def firstTime(fieldManager)
    objId = fieldManager.getObjId
    objId == nil
  end

  def prevValue(objId)
    prevObject = ObjectStore.getObjectStore.get(@objectType, objId)
    prevObject.send(name)
  end

  def valueFromCGI(fieldManager)
    objId = fieldManager.getObjId
    firstTime = firstTime fieldManager
    if writeOnce && !firstTime
      value = prevValue objId
    else
      value = fieldManager.get(name)
    end
    value = processBeforeVerify value
    value
  end

  def verifiedValue(fieldManager)
    value = valueFromCGI(fieldManager)
    verify(value, fieldManager.getObjId)
    value
  end

  def processBeforeVerify(value)
    value = @default if value == nil
    value
  end

	# Given the SQL value string, returns a Ruby-native value.
  def valueFromSQL(string)
    string
  end

  def valueAsHTML(dbObject)
    dbObject.send(name)
  end

  def setDefault(linkField, fieldName)
    linkField.listener = self
    @defaultFieldName = fieldName
  end

  def javaScriptFunction
    nil
  end

	def viewer(value, objId)
		self.class.viewerType.new(value, self, objId)
	end

	def <=>(other)
		if @objectType == other.objectType && name == other.name
			0
		else
			id <=> other.id
		end
	end

	def dbWillAutomaticallyWrite
		false
	end
end
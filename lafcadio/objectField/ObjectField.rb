require 'lafcadio/util/EnglishUtil'
require 'lafcadio/objectField/FieldViewer'
require 'lafcadio/objectField/FieldValueError'

class ObjectField
	include Comparable

  attr_reader :name, :englishName, :defaultFieldName, :objectType
  attr_accessor :notNull, :hideLabel, :writeOnce, :unique, :hideDisplay,
      :default, :dbFieldName, :notUniqueMsg

  def ObjectField.valueType
    Object
  end

  def ObjectField.viewerType
    FieldViewer
  end

  def initialize (objectType, name, englishName = nil)
		require 'lafcadio/objectStore/ObjectStore'

    @objectType = objectType
    @name = name
		@dbFieldName = @name
		if englishName == nil
			@englishName = EnglishUtil.camelCaseToEnglish(name).capitalize
		else
			@englishName = englishName
		end
    @notNull = true
    @hideLabel = false
    @unique = false
    @default = nil
    @objectStore = ObjectStore.getObjectStore
  end

  def nullErrorMsg
		EnglishUtil.sentence "Please enter %a %nam.", englishName.downcase
  end

  def verify (value, objId)
    if value == nil && notNull
      raise FieldValueError, nullErrorMsg, caller
    end
    if value != nil
      valueType = self.type.valueType
			unless value.type <= valueType
        raise FieldValueError, 
						"#{name} needs an object of type #{valueType.name}", caller
      end
      verifyUniqueness(value, objId) if unique
    end
  end

  def verifyUniqueness (value, objId)
    collection = @objectStore.getAll(@objectType)
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

  def nameForSQL
    dbFieldName
  end

  def valueForSQL (value)
    value || 'null'
  end

  def firstTime (fieldManager)
    objId = fieldManager.getObjId
    objId == nil
  end

  def prevValue(objId)
    prevObject = @objectStore.get(@objectType, objId)
    prevObject.send(name)
  end

  def valueFromCGI (fieldManager)
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

  def verifiedValue (fieldManager)
    value = valueFromCGI(fieldManager)
    verify (value, fieldManager.getObjId)
    value
  end

  def processBeforeVerify (value)
    value = @default if value == nil
    value
  end

  def valueFromSQL (string)
    string
  end

  def valueAsHTML (dbObject)
    dbObject.send(name)
  end

  def setDefault (linkField, fieldName)
    linkField.listener = self
    @defaultFieldName = fieldName
  end

  def javaScriptFunction
    nil
  end

	def viewer (value, objId)
		self.type.viewerType.new(value, self, objId)
	end

	def <=> (other)
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
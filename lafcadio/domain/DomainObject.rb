require 'lafcadio/objectField/LinkField'
require 'lafcadio/objectStore/DomainComparable'
require 'lafcadio/objectStore/DomainObjectProxy'

class DomainObject
	@@subclassHash = {}

	COMMIT_ADD = 1
	COMMIT_EDIT = 2
	COMMIT_DELETE = 3

	include DomainComparable

	def DomainObject.classFields
		raise "classFields needs to be defined for #{ self.name }"
	end

	def DomainObject.abstractSubclasses
		require 'lafcadio/domain/MapObject'
		[ MapObject ]
	end

	def DomainObject.selfAndConcreteSuperclasses
		classes = [ ]
		anObjectType = self
		until (abstractSubclasses.index(anObjectType) != nil ||
				anObjectType == DomainObject)
			classes << anObjectType
			anObjectType = anObjectType.superclass
		end
		classes
	end

	def DomainObject.method_missing (methodId)
		require 'lafcadio/domain/ObjectType'
		ObjectType.new(self).send(methodId.id2name)
	end

	def DomainObject.getField (fieldName)
		field = nil
		self.classFields.each { |aField|
			field = aField if aField.name == fieldName
		}
		field
	end

	def DomainObject.sqlPrimaryKeyName
		'objId'
	end

  def DomainObject.dependentClasses
    dependentClasses = {}
		DomainObject.subclasses.each { |aClass|
			if aClass != DomainObjectProxy &&
					(!DomainObject.abstractSubclasses.index(aClass))
				aClass.classFields.each { |field|
					if field.type <= LinkField && field.linkedType == self.objectType
						dependentClasses[aClass] = field
					end
				}
			end
    }
    dependentClasses
  end

	def DomainObject.objectType
		self
	end

	def DomainObject.allFields
		allFields = []
		selfAndConcreteSuperclasses.each { |aClass|
			aClass.classFields.each { |field| allFields << field }
		}
		allFields
	end
	
	def DomainObject.inherited (subclass)
		@@subclassHash[subclass] = true
	end
	
	def DomainObject.subclasses
		@@subclassHash.keys
	end

  attr_accessor :delete, :errorMessages, :objId, :lastCommit, :fields
  protected :fields

  def initialize (fieldHash)
		@objId = fieldHash["objId"] != nil ? fieldHash["objId"].to_i : nil
    @errorMessages = []
    @fields = {}
    type.allFields.each { |field|
    	self.send("#{ field.name }=", fieldHash[field.name])
		}
  end
  
  def method_missing (methId, arg1 = nil)
		methodName = methId.id2name
		getter = false
		setter = false
		field = nil
		type.allFields.each { |aField|
			if aField.name == methodName
				getter = true
				field = aField
			elsif "#{ aField.name }=" == methodName
				setter = true
				field = aField
			end
		}
		if getter
			@fields[field.name]
		elsif setter
			if field.type <= LinkField
				if arg1.type != DomainObjectProxy && arg1
					arg1 = DomainObjectProxy.new(arg1)
				end
			end
			@fields[field.name] = arg1
		else
			super (methId)
		end
  end

	def objectType
		self.type.objectType
	end

	def preCommitTrigger
		nil
	end

	def postCommitTrigger
		nil
	end

	def delete= (value)
		if value && !objId
			raise "No point deleting an object that's not already in the DB"
		end
		@delete = value
	end

	def to_s
		raise "Don't make me into a string unless the type asks"
	end
	
	def clone
		copy = super
		copy.fields = @fields.clone
		copy
	end
end

require 'lafcadio/objectStore/DomainObjectProxy'
require 'lafcadio/objectStore/DomainObjectInitError'
require 'lafcadio/objectField/ObjectField'
require 'lafcadio/objectField/LinkFieldViewer'

class LinkField < ObjectField
  def LinkField.viewerType
    LinkFieldViewer
  end

  attr_reader :linkedType
  attr_accessor :listener, :objectStore, :newDuringEdit, :sortField

  def initialize (objectType, linkedType, name = nil, englishName = nil)
		unless name
			linkedType.name =~ /::/
			name = $' || linkedType.name
			name = StrUtil.decapitalize name
		end
    super (objectType, name, englishName)
    @linkedType = linkedType
    @listener = nil
		@newDuringEdit = true
  end

  def valueForSQL (value)
		if value == nil
			"null"
		elsif value.objId
			value.objId
		else
			raise DomainObjectInitError, "Can't commit #{name} without objId", caller
		end
  end

  def valueFromCGI (fieldManager)
    objId = fieldManager.getInt(name)
		if objId != nil
	    @objectStore.get(@linkedType, objId)
		else
			nil
		end
  end

  def valueFromSQL (string)
		string != nil ? DomainObjectProxy.new(@linkedType, string.to_i) : nil
  end

  def valueAsHTML (dbObject)
    obj = super(dbObject)
    obj != nil ? obj.name : ""
  end

	def verify (value, objId)
		super
		if @linkedType != @objectType && objId
			subsetLinkField = nil
			@linkedType.classFields.each { |field|
				if field.type == SubsetLinkField && field.subsetField == @name				
					subsetLinkField = field
				end
			}
			if subsetLinkField
				begin
					prevObj = @objectStore.get(objectType, objId)
					prevObjLinkedTo = prevObj.send(name)
					possiblyMyObj = prevObjLinkedTo.send(subsetLinkField.name)
					if possiblyMyObj && possiblyMyObj.objId == objId
						cantChangeMsg = <<-MSG
This #{@objectType.englishName} is selected as the #{subsetLinkField.englishName} in #{@linkedType.englishName} \"#{prevObjLinkedTo.name}\". To change the #{subsetLinkField.englishName} this #{@objectType.englishName} belongs to, you must first change the #{subsetLinkField.englishName} in #{@linkedType.englishName} \"#{prevObjLinkedTo.name}\".
						MSG
						raise FieldValueError, cantChangeMsg, caller
					end
				rescue DomainObjectNotFoundError
					# no previous value, so nothing to check for
				end
			end
		end
	end
end


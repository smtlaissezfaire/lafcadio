require 'lafcadio/util'
require 'lafcadio/objectField/ObjectField'

module Lafcadio
	class LinkField < ObjectField
		def LinkField.instantiationParameters( fieldElt )
			parameters = super( fieldElt )
			linkedTypeStr = fieldElt.attributes['linkedType']
			linkedType = DomainObject.getObjectTypeFromString( linkedTypeStr )
			parameters['linkedType'] = linkedType
			parameters
		end

		def LinkField.instantiateWithParameters( domainClass, parameters )
			self.new( domainClass, parameters['linkedType'], parameters['name'],
								parameters['englishName'] )
		end

		attr_reader :linkedType
		attr_accessor :listener, :objectStore, :newDuringEdit, :sortField

		# [objectType] The domain class that this field belongs to.
		# [linkedType] The domain class that this field points to.
		# [name] The name of this field.
		# [englishName] The English name of this field.
		def initialize(objectType, linkedType, name = nil, englishName = nil)
			unless name
				linkedType.name =~ /::/
				name = $' || linkedType.name
				name = name.decapitalize
			end
			super(objectType, name, englishName)
			@linkedType = linkedType
			@listener = nil
			@newDuringEdit = true
		end

		def valueForSQL(value)
			require 'lafcadio/objectStore/DomainObjectInitError'
			if !value
				"null"
			elsif value.pkId
				value.pkId
			else
				raise( DomainObjectInitError, "Can't commit #{name} without pkId", 
				       caller )
			end
		end

		def valueFromSQL(string)
			require 'lafcadio/objectStore/DomainObjectProxy'
			string != nil ? DomainObjectProxy.new(@linkedType, string.to_i) : nil
		end

		def verify(value, pkId)
			super
			if @linkedType != @objectType && pkId
				subsetLinkField = nil
				@linkedType.classFields.each { |field|
					if field.class == SubsetLinkField && field.subsetField == @name
						subsetLinkField = field
					end
				}
				if subsetLinkField
					begin
						prevObj = ObjectStore.getObjectStore.get(objectType, pkId)
						prevObjLinkedTo = prevObj.send(name)
						possiblyMyObj = prevObjLinkedTo.send(subsetLinkField.name)
						if possiblyMyObj && possiblyMyObj.pkId == pkId
							cantChangeMsg = "You can't change that."
							raise FieldValueError, cantChangeMsg, caller
						end
					rescue DomainObjectNotFoundError
						# no previous value, so nothing to check for
					end
				end
			end
		end
	end
end

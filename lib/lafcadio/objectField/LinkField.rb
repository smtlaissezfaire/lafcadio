require 'lafcadio/util'
require 'lafcadio/objectField/ObjectField'

module Lafcadio
	# A LinkField is used to link from one domain class to another.
	class LinkField < ObjectField
		def LinkField.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			self.new( domainClass, parameters['linkedType'], parameters['name'],
								parameters['englishName'], parameters['deleteCascade'] )
		end

		def LinkField.instantiationParameters( fieldElt ) #:nodoc:
			parameters = super( fieldElt )
			linkedTypeStr = fieldElt.attributes['linkedType']
			linkedType = DomainObject.getObjectTypeFromString( linkedTypeStr )
			parameters['linkedType'] = linkedType
			parameters['deleteCascade'] = fieldElt.attributes['deleteCascade'] == 'y'
			parameters
		end

		attr_reader :linkedType
		attr_accessor :deleteCascade

		# [objectType]    The domain class that this field belongs to.
		# [linkedType]    The domain class that this field points to.
		# [name]          The name of this field.
		# [englishName]   The English name of this field. (Deprecated)
		# [deleteCascade] If this is true, deleting the domain object that is linked
		#                 to will cause this domain object to be deleted as well.
		def initialize( objectType, linkedType, name = nil, englishName = nil,
		                deleteCascade = false )
			unless name
				linkedType.name =~ /::/
				name = $' || linkedType.name
				name = name.decapitalize
			end
			super(objectType, name, englishName)
			( @linkedType, @deleteCascade ) = linkedType, deleteCascade
		end

		def valueFromSQL(string) #:nodoc:
			require 'lafcadio/objectStore/DomainObjectProxy'
			string != nil ? DomainObjectProxy.new(@linkedType, string.to_i) : nil
		end

		def valueForSQL(value) #:nodoc:
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

		def verify(value, pkId) #:nodoc:
			super
			if @linkedType != @objectType && pkId
				subsetLinkField = @linkedType.classFields.find { |field|
					field.class == SubsetLinkField && field.subsetField == @name
				}
				if subsetLinkField
					verify_subset_link_field( subsetLinkField, pkId )
				end
			end
		end

		def verify_subset_link_field( subsetLinkField, pkId )
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

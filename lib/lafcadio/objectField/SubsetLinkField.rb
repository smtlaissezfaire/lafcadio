require 'lafcadio/objectField/LinkField'

module Lafcadio
	class SubsetLinkField < LinkField #:nodoc:
		def self.instantiateWithParameters( domainClass, parameters )
			self.new( domainClass, parameters['linkedType'],
			          parameters['subsetField'], parameters['name'],
								parameters['englishName'] )
		end

		def self.instantiationParameters( fieldElt )
			parameters = super( fieldElt )
			parameters['subsetField'] = fieldElt.attributes['subsetField']
			parameters
		end
		
		attr_accessor :subsetField

		def initialize(objectType, linkedType, subsetField,
				name = linkedType.name.downcase, englishName = nil)
			super(objectType, linkedType, name, englishName)
			@subsetField = subsetField
		end
	end
end
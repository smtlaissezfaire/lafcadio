require 'lafcadio/objectField/ObjectField'

module Lafcadio
	# DecimalField represents a decimal value.
	class DecimalField < ObjectField
		attr_reader :precision

		def self.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			self.new( domainClass, parameters['name'], parameters['precision'],
								parameters['englishName'] )
		end

		def self.instantiationParameters( fieldElt ) #:nodoc:
			parameters = super( fieldElt )
			parameters['precision'] = fieldElt.attributes['precision'].to_i
			parameters
		end
		
		def self.valueType #:nodoc:
			Numeric
		end

		# [objectType]  The domain class that this field belongs to.
		# [name]        The name of this field.
		# [precision]   The expected field precision. (Deprecated)
		# [englishName] The English name of this field. (Deprecated)
		def initialize(objectType, name, precision, englishName = nil)
			super(objectType, name, englishName)
			@precision = precision
		end

		def processBeforeVerify(value) #:nodoc:
			value = super value
			value != nil && value != '' ? value.to_f : nil
		end

		def valueFromSQL(string, lookupLink = true) #:nodoc:
			string != nil ? string.to_f : nil
		end
	end
end
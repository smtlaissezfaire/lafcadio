require 'lafcadio/objectField/ObjectField'

module Lafcadio
	class DecimalField < ObjectField
		attr_reader :precision

		def DecimalField.valueType
			Numeric
		end

		def DecimalField.instantiationParameters( fieldElt )
			parameters = super( fieldElt )
			parameters['precision'] = fieldElt.attributes['precision'].to_i
			parameters
		end
		
		def DecimalField.instantiateWithParameters( domainClass, parameters )
			self.new( domainClass, parameters['name'], parameters['precision'],
								parameters['englishName'] )
		end

		def initialize(objectType, name, precision, englishName = nil)
			super(objectType, name, englishName)
			@precision = precision
		end

		def valueFromSQL(string, lookupLink = true)
			string != nil ? string.to_f : nil
		end

		def processBeforeVerify(value)
			value = super value
			value != nil && value != '' ? value.to_f : nil
		end
	end
end
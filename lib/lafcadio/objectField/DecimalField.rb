require 'lafcadio/objectField/ObjectField'

module Lafcadio
	# DecimalField represents a decimal value.
	class DecimalField < ObjectField
		def self.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			self.new( domainClass, parameters['name'], parameters['englishName'] )
		end

		def self.valueType #:nodoc:
			Numeric
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
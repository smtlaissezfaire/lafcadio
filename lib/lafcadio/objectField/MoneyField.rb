require 'lafcadio/objectField/DecimalField'

module Lafcadio
	class MoneyField < DecimalField #:nodoc:
		def MoneyField.instantiateWithParameters( domainClass, parameters )
			self.new( domainClass, parameters['name'], parameters['englishName'] )
		end

		def initialize(objectType, name, englishName = nil)
			super(objectType, name, 2, englishName)
		end
	end
end
require 'lafcadio/objectField/TextField'

module Lafcadio
	class EnumField < TextField
		def EnumField.instantiationParameters( fieldElt )
			parameters = super( fieldElt )
			if fieldElt.elements['enums'][1].attributes['key']
				enumValues = []
				fieldElt.elements.each( 'enums/enum' ) { |enumElt|
					enumValues << enumElt.attributes['key']
					enumValues << enumElt.text.to_s
				}
				parameters['enums'] = QueueHash.new( *enumValues )
			else
				parameters['enums'] = []
				fieldElt.elements.each( 'enums/enum' ) { |enumElt|
					parameters['enums'] << enumElt.text.to_s
				}
			end
			parameters
		end
		
		def EnumField.instantiateWithParameters( domainClass, parameters )
			self.new( domainClass, parameters['name'], parameters['enums'],
								parameters['englishName'] )
		end

		attr_reader :enums

		def initialize(objectType, name, enums, englishName = nil)
			require 'lafcadio/util/QueueHash'
			super objectType, name, englishName
			if enums.class == Array 
				@enums = QueueHash.newFromArray enums
			else
				@enums = enums
			end
		end
		
		def valueForSQL(value)
			value != '' ?(super(value)) : 'null'
		end
	end
end

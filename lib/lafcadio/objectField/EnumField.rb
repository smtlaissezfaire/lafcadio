require 'lafcadio/objectField/TextField'

module Lafcadio
	# EnumField represents an enumerated field that can only be set to one of a
	# set range of string values. To set the enumeration in the class definition
	# XML, use the following format:
	#   <field name="flavor" class="EnumField">
	#     <enums>
	#       <enum>Vanilla</enum>
	#       <enum>Chocolate</enum>
	#       <enum>Lychee</enum>
	#     </enums>
	#   </field>
	# If you're defining the field in Ruby, you can simply pass in an array of
	# enums as the +enums+ argument.
	#
	class EnumField < TextField
		def self.instantiateWithParameters( domainClass, parameters ) #:nodoc:
			self.new( domainClass, parameters['name'], parameters['enums'],
								parameters['englishName'] )
		end

		def self.enum_queue_hash( fieldElt )
			enumValues = []
			fieldElt.elements.each( 'enums/enum' ) { |enumElt|
				enumValues << enumElt.attributes['key']
				enumValues << enumElt.text.to_s
			}
			QueueHash.new( *enumValues )
		end

		def self.instantiationParameters( fieldElt ) #:nodoc:
			parameters = super( fieldElt )
			if fieldElt.elements['enums'][1].attributes['key']
				parameters['enums'] = enum_queue_hash( fieldElt )
			else
				parameters['enums'] = []
				fieldElt.elements.each( 'enums/enum' ) { |enumElt|
					parameters['enums'] << enumElt.text.to_s
				}
			end
			parameters
		end
		
		attr_reader :enums

		# [objectType]  The domain class that this field belongs to.
		# [name]        The name of this domain class.
		# [enums]       An array of Strings representing the possible choices for
		#               this field.
		# [englishName] The English name of this field. (Deprecated)
		def initialize(objectType, name, enums, englishName = nil)
			require 'lafcadio/util/QueueHash'
			super objectType, name, englishName
			if enums.class == Array 
				@enums = QueueHash.newFromArray enums
			else
				@enums = enums
			end
		end
		
		def valueForSQL(value) #:nodoc:
			value != '' ?(super(value)) : 'null'
		end
	end
end

require 'lafcadio/includer'
Includer.include( 'domain' )
require 'lafcadio/objectField'

class ClassDefinitionXmlParser
	class InvalidDataError < ArgumentError
	end

	class FieldAttribute
		INTEGER = 1
		BOOLEAN = 2
		ENUM    = 3
		HASH    = 4
		
		attr_reader :name, :valueClass
	
		def initialize( name, valueClass, objectFieldClass = nil )
			@name = name; @valueClass = valueClass
			@objectFieldClass = objectFieldClass
		end
		
		def valueFromString( valueStr )
			if @valueClass == INTEGER
				valueStr.to_i
			elsif @valueClass == BOOLEAN
				valueStr == 'y'
			elsif @valueClass == ENUM
				eval "#{ @objectFieldClass.name }::#{ valueStr }"
			end
		end
		
		def valueFromElt( elt )
			hash = {}
			elt.elements.each( EnglishUtil.singular( @name ) ) { |subElt|
				key = subElt.attributes['key'] == 'true'
				value = subElt.text.to_s
				hash[key] = value
			}
			hash
		end
		
		def maybeSetFieldAttr( field, fieldElt )
			setterMethod = "#{ name }="
			if field.respond_to?( setterMethod )
				if valueClass != FieldAttribute::HASH
					if ( attrStr = fieldElt.attributes[name] )
						field.send( setterMethod, valueFromString( attrStr ) )
					end
				else
					if ( attrElt = fieldElt.elements[name] )
						field.send( setterMethod, valueFromElt( attrElt ) )
					end
				end
			end
		end
	end

	def initialize( domainClass, xml )
		@domainClass = domainClass; @xml = xml
	end

	def execute
		require 'rexml/document'
		require 'lafcadio/util'
		
		namesProcessed = {}
		fields = []
		rexmlDoc = REXML::Document.new( @xml )
		rexmlDoc.root.elements.each('field') { |fieldElt|
			className = fieldElt.attributes['class']
			fieldClass = ClassUtil.getClass( className )
			name = fieldElt.attributes['name']
			unless fieldClass
				msg = "Couldn't find field class '#{ className }' for field '#{ name }'"
				raise( StandardError, msg, caller )
			end
			raise InvalidDataError if namesProcessed[name]
			field = fieldClass.instantiateFromXml( @domainClass, fieldElt )
			possibleFieldAttributes.each { |fieldAttr|
				fieldAttr.maybeSetFieldAttr( field, fieldElt )
			}
			fields << field
			namesProcessed[name] = true
		}
		fields
	end
	
	def possibleFieldAttributes
		fieldAttr = []
		fieldAttr << FieldAttribute.new( 'size', FieldAttribute::INTEGER )
		fieldAttr << FieldAttribute.new( 'unique', FieldAttribute::BOOLEAN )
		fieldAttr << FieldAttribute.new( 'notNull', FieldAttribute::BOOLEAN )
		fieldAttr << FieldAttribute.new( 'enumType', FieldAttribute::ENUM,
		                                 BooleanField )
		fieldAttr << FieldAttribute.new( 'enums', FieldAttribute::HASH )
		fieldAttr << FieldAttribute.new( 'range', FieldAttribute::ENUM,
		                                 DateField )
		fieldAttr << FieldAttribute.new( 'large', FieldAttribute::BOOLEAN )
	end
end

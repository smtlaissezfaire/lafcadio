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
		require 'rexml/document'

		@domainClass = domainClass
		@xmlDocRoot = REXML::Document.new( xml ).root
	end

	def getClassFields
		require 'lafcadio/util'
		
		namesProcessed = {}
		fields = []
		@xmlDocRoot.elements.each('field') { |fieldElt|
			className = fieldElt.attributes['class']
			name = fieldElt.attributes['name']
			begin
				fieldClass = ClassUtil.getClass( className )
				raise InvalidDataError if namesProcessed[name]
				field = fieldClass.instantiateFromXml( @domainClass, fieldElt )
				possibleFieldAttributes.each { |fieldAttr|
					fieldAttr.maybeSetFieldAttr( field, fieldElt )
				}
				fields << field
				namesProcessed[name] = true
			rescue MissingError
				msg = "Couldn't find field class '#{ className }' for field '#{ name }'"
				raise( MissingError, msg, caller )
			end
		}
		fields
	end
	
	def sqlPrimaryKeyName
		@xmlDocRoot.attributes['sqlPrimaryKeyName']
	end
	
	def tableName
		@xmlDocRoot.attributes['tableName']
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

require 'lafcadio/includer'
Includer.include( 'domain' )
require 'lafcadio/objectField'
require 'lafcadio/util'		
require 'rexml/document'

module Lafcadio
	class ClassDefinitionXmlParser # :nodoc: all
		def initialize( domainClass, xml )
			@domainClass = domainClass
			@xmlDocRoot = REXML::Document.new( xml ).root
			@namesProcessed = {}
		end
		
		def get_class_field( fieldElt )
			className = fieldElt.attributes['class'].to_s
			name = fieldElt.attributes['name']
			begin
				fieldClass = Class.getClass( 'Lafcadio::' + className )
				register_name( name )
				field = fieldClass.instantiateFromXml( @domainClass, fieldElt )
				set_field_attributes( field, fieldElt )
			rescue MissingError
				msg = "Couldn't find field class '#{ className }' for field " +
				      "'#{ name }'"
				raise( MissingError, msg, caller )
			end
			field
		end

		def getClassFields
			namesProcessed = {}
			fields = []
			@xmlDocRoot.elements.each('field') { |fieldElt|
				fields << get_class_field( fieldElt )
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

		def register_name( name )
			raise InvalidDataError if @namesProcessed[name]
			@namesProcessed[name] = true
		end
		
		def set_field_attributes( field, fieldElt )
			possibleFieldAttributes.each { |fieldAttr|
				fieldAttr.maybeSetFieldAttr( field, fieldElt )
			}
		end

		def sqlPrimaryKeyName
			@xmlDocRoot.attributes['sqlPrimaryKeyName']
		end
		
		def tableName
			@xmlDocRoot.attributes['tableName']
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

			def valueFromElt( elt )
				hash = {}
				elt.elements.each( English.singular( @name ) ) { |subElt|
					key = subElt.attributes['key'] == 'true'
					value = subElt.text.to_s
					hash[key] = value
				}
				hash
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
		end

		class InvalidDataError < ArgumentError; end
	end
end
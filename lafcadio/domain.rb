require 'lafcadio/includer'
Includer.include( 'domain' )

class ClassDefinitionXmlParser
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
				key = subElt.attributes['value'] == 'true'
				value = subElt.text.to_s
				hash[key] = value
			}
			hash
		end
		
		def maybeSetFieldAttr( field, fieldElt )
			if valueClass != FieldAttribute::HASH
				if ( attrStr = fieldElt.attributes[name] )
					field.send( "#{ name }=", valueFromString( attrStr ) )
				end
			else
				if ( attrElt = fieldElt.elements[name] )
					field.send( "#{ name }=", valueFromElt( attrElt ) )
				end
			end
		end
	end

	def initialize( domainClass )
		@domainClass = domainClass
	end
	
	def execute
		require 'rexml/document'
		require 'lafcadio/util'
		
		fields = []
		dirName = LafcadioConfig.new['classDefinitionDir']
		xmlFileName = ClassUtil.bareClassName( @domainClass ) + '.xml'
		xmlPath = File.join( dirName, xmlFileName )
		file = File.new( xmlPath )
		rexmlDoc = REXML::Document.new( file )
		rexmlDoc.root.elements.each('field') { |fieldElt|
			fieldClass = ClassUtil.getClass( fieldElt.attributes['class'] )
			field = fieldClass.new( @domainClass, fieldElt.attributes['name'] )
			possibleFieldAttributes.each { |fieldAttr|
				fieldAttr.maybeSetFieldAttr( field, fieldElt )
			}
			if ( size = fieldElt.attributes['size'] )
				field.size = size.to_i
			end
			fields << field
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
	end
end

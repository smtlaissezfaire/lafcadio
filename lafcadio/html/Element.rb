require 'lafcadio/html/HTML'

class HTML
	class Element < Array
		def Element.tagName
			aClass = self
			aClass = aClass.superclass while aClass.name !~ /::/
			$'.downcase
		end

		def Element.requiredAttributes
			[]
		end

		def Element.attributes
			[ 'class', 'type' ]
		end

		def methodName(attribute)
			if attribute == 'type'
				'eltType'
			elsif attribute == 'class'
				'eltClass'
			else
				attribute
			end
		end

		def initialize(attHash = {})
			self.class.requiredAttributes.each { |required|
				raise "needs #{required}" unless attHash[required]
			}
			self.class.attributes.each { |att|
				attName = methodName att
				eval %{
      	  def self.#{attName}
        	  @#{attName}
	        end

  	      def self.#{attName}=(value)
    	      @#{attName} = value
      	  end

					@#{attName} = attHash[att]
				}
			}
		end

		def toHTML
			tag = "<" + self.class.tagName
			self.class.attributes.each { |att|
				attName = methodName att
				if(value = self.send(attName))
					if [ true, false ].index(value) == nil
						tag += " #{att}='#{value}'"
					else
						tag += " #{att}" if value
					end
				end
			}
			tag += ">"
			tag
		end
	end
end
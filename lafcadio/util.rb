require 'lafcadio/includer'
Includer.include( 'util' )

class MissingError < RuntimeError
end

class Class < Module
	# Given a String, returns a class object by the same name.
	def self.getClass(className)
		theClass = nil
		ObjectSpace.each_object(Class) { |aClass|
			theClass = aClass if aClass.name == className
		}
		if theClass
			theClass
		else
			raise( MissingError, "Couldn't find class \"#{ className }\"", caller )
		end
	end
	
	# Returns the name of <tt>aClass</tt> itself, stripping off the names of any 
	# containing modules or outer classes.
	def bareName
		name =~ /::/
		$' || name
	end
end
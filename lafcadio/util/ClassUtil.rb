class ClassUtil
	# Returns an array of all the known subclasses of <tt>theClass</tt>.
  def ClassUtil.subclasses(theClass)
    subclasses = []
    ObjectSpace.each_object(Class) { |aClass|
			if aClass <= theClass && aClass != theClass
        subclasses << aClass
      end
    }
    subclasses
  end

	# Returns the name of <tt>aClass</tt> itself, stripping off the names of any 
	# containing modules or outer classes.
	def ClassUtil.bareClassName(aClass)
		aClass.name =~ /::/
		$' || aClass.name
	end
	
	# Given a String, returns a class object by the same name.
	def ClassUtil.getClass(className)
		theClass = nil
		ObjectSpace.each_object(Class) { |aClass|
			theClass = aClass if aClass.name == className
		}
		theClass
	end
end

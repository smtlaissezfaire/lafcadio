class ClassUtil
  def ClassUtil.subclasses(theClass)
    subclasses = []
    ObjectSpace.each_object(Class) { |aClass|
			if aClass <= theClass && aClass != theClass
        subclasses << aClass
      end
    }
    subclasses
  end

	def ClassUtil.bareClassName(aClass)
		aClass.name =~ /::/
		$' || aClass.name
	end
	
	def ClassUtil.getClass(className)
		theClass = nil
		ObjectSpace.each_object(Class) { |aClass|
			theClass = aClass if aClass.name == className
		}
		theClass
	end
end

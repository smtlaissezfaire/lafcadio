require 'lafcadio/objectStore/CouldntMatchObjectTypeError'
require 'lafcadio/domain/DomainObject'

class ClassUtil
  def ClassUtil.getObjectTypeFromString (typeString)
		require 'lafcadio/util/Config'
    objectType = nil
		typeString =~ /([^\:]*)$/
		config = Config.new
		classPath = config['classpath']
		domainDirStr = config['domainDirs']
		if domainDirStr
			domainDirs = domainDirStr.split(',')
		else
			domainDirs = [ classPath + 'domain/' ]
		end
		domainDirs.each { |domainDir|
			if Dir.entries(domainDir).index("#{$1}.rb")
				require "#{ domainDir }#{ $1 }"
				ClassUtil.subclasses(DomainObject).each { |subclass|
					objectType = subclass if subclass.to_s == typeString
				}
			end
		}
		if objectType
			objectType
		else
			raise CouldntMatchObjectTypeError,
					"couldn't match objectType #{typeString}", caller
		end
  end

  def ClassUtil.subclasses (theClass)
    subclasses = []
    ObjectSpace.each_object(Class) { |aClass|
			if aClass <= theClass && aClass != theClass
        subclasses << aClass
      end
    }
    subclasses
  end

	def ClassUtil.bareClassName (aClass)
		aClass.name =~ /::/
		$' || aClass.name
	end
	
	def ClassUtil.getClass (className)
		theClass = nil
		ObjectSpace.each_object(Class) { |aClass|
			theClass = aClass if aClass.name == className
		}
		theClass
	end
end

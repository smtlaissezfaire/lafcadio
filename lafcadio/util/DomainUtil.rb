class DomainUtil
  def DomainUtil.getObjectTypeFromString(typeString)
		require 'lafcadio/domain/DomainObject'
		require 'lafcadio/objectStore/CouldntMatchObjectTypeError'
		require 'lafcadio/util/Config'
    objectType = nil
		typeString =~ /([^\:]*)$/
		fileName = $1
		config = Config.new
		classPath = config['classpath']
		domainDirStr = config['domainDirs']
		if domainDirStr
			domainDirs = domainDirStr.split(',')
		else
			domainDirs = [ classPath + 'domain/' ]
		end
		domainDirs.each { |domainDir|
			if Dir.entries(domainDir).index("#{fileName}.rb")
				require "#{ domainDir }#{ fileName }"
				DomainObject.subclasses.each { |subclass|
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
end
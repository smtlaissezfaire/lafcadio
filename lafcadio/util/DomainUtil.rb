require 'lafcadio/util'

class DomainUtil
	def DomainUtil.getDomainDirs
		config = LafcadioConfig.new
		classPath = config['classpath']
		domainDirStr = config['domainDirs']
		if domainDirStr
			domainDirs = domainDirStr.split(',')
		else
			domainDirs = [ classPath + 'domain/' ]
		end
	end

	# Looks for the domain class whose name equals <tt>typeString</tt>.
  def DomainUtil.getObjectTypeFromString(typeString)
		require 'lafcadio/domain/DomainObject'
		require 'lafcadio/objectStore/CouldntMatchObjectTypeError'
    objectType = nil
		typeString =~ /([^\:]*)$/
		fileName = $1
		getDomainDirs.each { |domainDir|
			if Dir.entries(domainDir).index("#{fileName}.rb")
				require "#{ domainDir }#{ fileName }"
			end
		}
		if (domainFilesStr = LafcadioConfig.new['domainFiles'])
			domainFilesStr.split(',').each { |domainFile|
				require domainFile
			}
		end
		DomainObject.subclasses.each { |subclass|
			objectType = subclass if subclass.to_s == typeString
		}
		if objectType
			objectType
		else
			raise CouldntMatchObjectTypeError,
					"couldn't match objectType #{typeString}", caller
		end
  end
end
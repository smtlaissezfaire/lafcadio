class Logger
	@@logging = true

	def Logger.setLogging (logging)
		@@logging = logging
	end

  def Logger.log (line, logName = "log")
		if @@logging
			begin
				logDir = (Config.new)['logdir']
		    fileName = logDir + logName
  		  file = File.open (fileName, File::APPEND | File::CREAT | File::WRONLY)
				file.write "#{ Time.now.to_s }: "
    		file.write line
		    file.write "\n"
  		  file.close
			rescue Errno::EACCES
				# fail silently
			end
		end
  end
end

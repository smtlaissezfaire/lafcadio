require 'lafcadio/util/LafcadioConfig'

module Lafcadio
	# A utility class for logging. You'll need to set "logdir" in your
	# LafcadioConfig file to use this.
	class Logger
		@@logging = true

		# Set <tt>logging</tt> to <tt>false</tt> to disable all logging through 
		# Logger; set it to <tt>true</tt> to turn it back on again.
		def Logger.setLogging(logging)
			@@logging = logging
		end

		# Logs <tt>line</tt> to file <tt>logName</tt>. Automatically appends the 
		# date and time to this line.
		 def Logger.log(line, logName = "log")
			if @@logging
				begin
					logDir =(LafcadioConfig.new)['logdir']
					fileName = logDir + logName
					file = File.open(fileName, File::APPEND | File::CREAT | File::WRONLY)
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
end
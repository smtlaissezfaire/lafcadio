module Lafcadio
	# LafcadioConfig is a Hash that takes its data from the config file. You'll 
	# have to set the location of that file before using it: Use 
	# LafcadioConfig.setFilename.
	#
	# LafcadioConfig expects its data to be colon-delimited, one key-value pair 
	# to a line. For example:
	#   dbuser:user
	#   dbpassword:password
	#   dbname:lafcadio_test
	#   dbhost:localhost
	class LafcadioConfig < Hash
		def LafcadioConfig.setFilename(filename)
			@@filename = filename
		end

		def initialize
		 file = File.new @@filename
			file.each_line { |line|
				line.chomp =~ /^(.*?):(.*)$/
				self[$1] = $2
			}
		end
	end
end
require 'lafcadio/util/Config'

class Redirect
	def initialize (localPath, solApDir = true)
		@localPath = localPath
		@soleApacheDirective = solApDir
	end

	def to_s
		config = Config.new
		str = "Location: #{config['url']}/#{@localPath}\n"
		str += "\n" if @soleApacheDirective
		str
	end
end
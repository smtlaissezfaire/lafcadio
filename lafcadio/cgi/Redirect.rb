require 'lafcadio/util/LafcadioConfig'

# The Redirect class represents an Apache directive to redirect a browser.
class Redirect
	# [localPath] The local part of the URL you want to redirect to. 
	# A leading slash is not necessary.
	# [solApDir] Set this to false if this is not the only Apache directive you
	# want to output. For example, a member login script might set a cookie and
	# redirect at the same time.
	def initialize(localPath, solApDir = true)
		@localPath = localPath
		@soleApacheDirective = solApDir
	end

	# Returns the Apache directive as a string.
	def to_s
		config = LafcadioConfig.new
		str = "Location: #{config['url']}/#{@localPath}\n"
		str += "\n" if @soleApacheDirective
		str
	end
end
class Includer # :nodoc:
	def Includer.include( subdir )
		dir = nil
		$:.each { |includeDir|
			attemptedDir = includeDir + '/lafcadio/' + subdir
			begin
				dir = Dir.open( attemptedDir )
			rescue Errno::ENOENT
				# wrong include directory, try again
			end
		}
		if dir
			dir.entries.each { |entry|
				require "lafcadio/#{ subdir }/#{ $1 }" if entry =~ /(.*)\.rb$/
			}
		end
	end
end
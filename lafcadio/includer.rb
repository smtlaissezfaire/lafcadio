class Includer
	def Includer.include( subdir )
		Dir.entries( "lafcadio/#{ subdir }" ).each { |entry|
			require "lafcadio/#{ subdir }/#{ $1 }" if entry =~ /(.*)\.rb/
		}
	end
end
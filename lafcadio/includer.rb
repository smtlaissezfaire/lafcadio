fileThatRequiredMe = $"[ ($".size - 2) ]
fileThatRequiredMe =~ /lafcadio\/(.*)\.rb/
subdir = $1
Dir.entries( "lafcadio/#{ subdir }" ).each { |entry|
	require "lafcadio/#{ subdir }/#{ $1 }" if entry =~ /(.*)\.rb/
}
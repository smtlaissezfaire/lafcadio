#! /usr/bin/env ruby
################################################################################
#                                                                              #
#  Name: install.rb                                                            #
#  Author: Sean E Russell <ser@germane-software.com>                           #
#  Version: $Id: install.rb,v 1.2 2003/10/08 03:55:00 francis Exp $
#  Date: *2002-174                                                             #
#  Description:                                                                #
#    This is a generic installation script for pure ruby sources.  Features    #
#          include:                                                            #
#          * Clean uninstall                                                   #
#          * Installation into an absolute path                                #
#          * Installation into a temp path (useful for systems like Portage)   #
#          * Noop mode, for testing                                            #
#    To set for a different system, change the SRC directory to point to the   #
#    package name / source directory for the project.                          #
#                                                                              #
################################################################################

# CHANGE THIS
SRC = 'lafcadio'
BIN = 'bin'
# CHANGE NOTHING BELOW THIS LINE

Dir.chdir ".." if Dir.pwd =~ /bin.?$/

require 'getoptlong'
require 'rbconfig'
require 'ftools'
require 'find'

opts = GetoptLong.new( [ '--uninstall',	'-u',		GetoptLong::NO_ARGUMENT],
											[ '--destdir', '-d', GetoptLong::REQUIRED_ARGUMENT ],
											[ '--target', '-t', GetoptLong::REQUIRED_ARGUMENT ],
											[ '--help', '-h', GetoptLong::NO_ARGUMENT],
											[ '--noop', '-n', GetoptLong::NO_ARGUMENT])


destdir = File.join Config::CONFIG['sitedir'], 
	"#{Config::CONFIG['MAJOR']}.#{Config::CONFIG['MINOR']}"

uninstall = false
append = nil
opts.each do |opt,arg|
	case opt
		when '--destdir'
			append = arg
		when '--uninstall'
			uninstall = true
		when '--target'
			destdir = arg
		when '--help'
			puts "Installs #{SRC}.\nUsage:\n\t#$0 [[-u] [-n] [-t <dir>|-d <dir>]|-h]"
			puts "\t-u --uninstall\tUninstalls the package"
			puts "\t-t --target\tInstalls the software at an absolute location, EG:"
			puts "\t    #$0 -t /usr/local/lib/ruby"
			puts "\t  will put the software directly underneath /usr/local/lib/ruby;"
			puts "\t  IE, /usr/local/lib/ruby/#{SRC}"
			puts "\t-d --destdir\tInstalls the software at a relative location, EG:"
			puts "\t    #$0 -d /tmp"
			puts "\t  will put the software under tmp, using your ruby environment."
			puts "\t  IE, /tmp/#{destdir}/#{SRC}"
			puts "\t-n --noop\tDon't actually do anything; just print out what it"
			puts "\t  would do."
			exit 0
		when '--noop'
			NOOP = true
	end
end

destdir = File.join append, destdir if append

def install destdir
	puts "Installing in #{destdir}"
	begin
		Find.find(SRC) { |file|
			next if file =~ /CVS|\.svn/
			dst = File.join( destdir, file )
			if defined? NOOP
				puts ">> #{dst}" if file =~ /\.rb$/
			else
				File.makedirs( File.dirname(dst) )
				File.install(file, dst, 0644, true) if file =~ /\.rb$/
			end
		}
	rescue
		puts $!
	end
	puts "Installing binaries in #{ Config::CONFIG['bindir'] }"
	begin
		Dir.entries( BIN ).each { |entry|
			src = File.join( BIN, entry )
			next unless FileTest.executable?( src ) && !FileTest.directory?( src )
			dst = File.join( Config::CONFIG['bindir'], entry )
			if defined? NOOP
				puts ">> #{ dst }"
			else
				File.install( src, dst, 0755, true )
			end
		}
	rescue
		puts $!
	end
end

def uninstall destdir
	puts "Uninstalling in #{destdir}"
	begin
		puts "Deleting:"
		dirs = []
		Find.find(File.join(destdir,SRC)) do |file| 
			if defined? NOOP
				puts "-- #{file}" if File.file? file
			else
				File.rm_f file,true if File.file? file
			end
			dirs << file if File.directory? file
		end
		dirs.sort { |x,y|
			y.length <=> x.length 	
		}.each { |d| 
			if defined? NOOP
				puts "-- #{d}"
			else
				puts d
				Dir.delete d
			end
		}
	rescue
	end
	puts "Uninstalling binaries in #{ Config::CONFIG['bindir'] }"
	begin
		Dir.entries( BIN ).each { |entry|
			orig = File.join( BIN, entry )
			next unless FileTest.executable?( orig ) && !FileTest.directory?( orig )
			to_uninstall = File.join( Config::CONFIG['bindir'], entry )
			if defined? NOOP
				puts "-- #{to_uninstall}" if File.file? to_uninstall
			else
				File.rm_f to_uninstall,true if File.file? to_uninstall
			end
		}
	rescue
	end
end

if uninstall
	uninstall destdir
else
	install destdir
end

require 'rubygems'
spec = Gem::Specification.new do |s|
	s.add_dependency( 'log4r' )
	s.add_dependency( 'extensions' )
	s.name = 'lafcadio'
	s.version = '0.7.0'
	s.platform = Gem::Platform::RUBY
	s.date = Time.now
	s.summary = "Lafcadio is an object-relational mapping layer"
	s.description = <<-DESC
Lafcadio is an object-relational mapping layer for Ruby and MySQL. It lets you treat database rows like first-class Ruby objects, minimizing the amount of time you have to spend thinking about MySQL vagaries so you can spend more time thinking about your program's logic. It also offers extensive support for unit-testing complex database logic without running cumbersome setup scripts.
	DESC
	s.require_paths = [ 'lib' ]
	s.files = Dir.glob( 'lib/**/*' ).delete_if { |item|
		item.include?('CVS')
	}
	s.author = "Francis Hwang"
	s.email = 'sera@fhwang.net'
	s.homepage = 'http://lafcadio.rubyforge.org/'
	s.autorequire = 'lafcadio'
	s.executables = [ 'lafcadio_schema' ]
	s.bindir = 'bin'
end
if $0==__FILE__
  Gem::Builder.new(spec).build
end

require 'rubygems'
spec = Gem::Specification.new do |s|
	s.name = 'lafcadio'
	s.version = '0.3.4'
	s.platform = Gem::Platform::RUBY
	s.date = Time.now
	s.summary = "Lafcadio is an object-relational mapping layer"
	s.require_paths = [ 'lafcadio' ]
	s.files = Dir.glob( 'lafcadio/**/*' ).delete_if { |item|
		item.include?('CVS')
	}
	s.author = "Francis Hwang"
	s.email = 'sera@fhwang.net'
	s.homepage = 'http://lafcadio.rubyforge.org/'
end
if $0==__FILE__
  Gem::Builder.new(spec).build
end

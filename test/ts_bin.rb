require 'test/unit'

class Test_lafcadio_schema < Test::Unit::TestCase
	def testGenerateSchema
		domain_classFile = "../test/mock/domain.rb"
		configFile = 'lafcadio/test/testconfig.dat'
		cmd = "../bin/lafcadio_schema -c #{ configFile } -C Client " +
		      domain_classFile
		results = `#{ cmd }`
		assert_not_nil( results =~ /standard_rate/, results )
	end
end
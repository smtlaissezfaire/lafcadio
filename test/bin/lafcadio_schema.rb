require 'runit/testcase'

class Test_lafcadio_schema < RUNIT::TestCase
	def testGenerateSchema
		domain_classFile = "../test/mock/domain/Client.rb"
		configFile = 'lafcadio/test/testconfig.dat'
		results = `../bin/lafcadio_schema -c #{ configFile } #{ domain_classFile }`
		assert_not_nil( results =~ /standard_rate/, results )
	end
end
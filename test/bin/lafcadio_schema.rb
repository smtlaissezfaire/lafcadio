require 'runit/testcase'

class Test_lafcadio_schema < RUNIT::TestCase
	def testGenerateSchema
		domainClassFile = "../test/mock/domain/Client.rb"
		configFile = 'lafcadio/test/testconfig.dat'
		results = `../bin/lafcadio_schema -c #{ configFile } #{ domainClassFile }`
		assert_not_nil( results =~ /standard_rate/, results )
	end
end
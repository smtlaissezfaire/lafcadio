require 'test/unit'

class Test_lafcadio_schema < Test::Unit::TestCase
	def testGenerateSchema
		domain_classFile = "../test/mock/domain/Client.rb"
		configFile = 'lafcadio/test/testconfig.dat'
		results = `../bin/lafcadio_schema -c #{ configFile } #{ domain_classFile }`
		assert_not_nil( results =~ /standard_rate/, results )
	end
end
class TestMockFieldManager < LafcadioTestCase
	def testConvertsIntsToStrings
		mfm = MockFieldManager.new({ 'objId' => 1 })
		assert_equal String, mfm.get("objId").class
	end
end
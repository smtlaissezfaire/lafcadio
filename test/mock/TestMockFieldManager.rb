class TestMockFieldManager < LafcadioTestCase
	def testConvertsIntsToStrings
		mfm = MockFieldManager.new ({ 'objId' => 1 })
		assert_equal String, mfm.get("objId").type
	end
end
class ContextualService
	def initialize (passKey)
		if passKey.class != Context
			raise ArgumentError,
					"#{ self.class.name.to_s } should only be instantiated by a Context",
					caller
		end
	end
end
class Query
	class Max < Query
		def fields
			"max(objId)"
		end
	end
end

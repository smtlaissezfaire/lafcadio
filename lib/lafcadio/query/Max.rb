module Lafcadio
	class Query
		class Max < Query
			def fields
				"max(pkId)"
			end
		end
	end
end
require 'lafcadio/domain'

module Domain
	class LineItem < Lafcadio::DomainObject
		def subtotal
			@quantity * @price
		end
	end
end


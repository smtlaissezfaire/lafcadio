require 'lafcadio/domain/DomainObject'

module Domain
	class LineItem < Lafcadio::DomainObject
		def subtotal
			@quantity * @price
		end
	end
end


require 'lafcadio/domain/DomainObject'

module Domain
	class LineItem < DomainObject
		def subtotal
			@quantity * @price
		end
	end
end


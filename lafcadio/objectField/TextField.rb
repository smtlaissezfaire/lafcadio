require 'lafcadio/objectField/ObjectField'

class TextField < ObjectField
  attr_accessor :large, :size

  def initialize(objectType, name, englishName = nil)
    super objectType, name, englishName
    @large = false
  end

  def valueForSQL(value)
		if value
			value = value.gsub( /(^|[^\\\n])(?=')/ ) { $& + "'" }
			value = value.gsub(/\\/) { '\\\\' }
  	  "'#{value}'"
		else
			"null"
		end
  end

	def valueFromCGI(fieldManager)
		value = super fieldManager
		value != '' ? value : nil
	end
end


require 'lafcadio/html/Input'
require 'lafcadio/html/Select'

# A class that generates HTML for use in getting a date value from a user. The 
# field names are given the suffixes ".dom", ".month", and ".year" for the day 
# of the month, month, and year, respectively. These field suffixes correspond 
# with the assumed suffixes in FieldManager#getDate.
#
# By default, DateWidget assumes you want the user to enter a date. If you only 
# want the user to enter a month, set DateWidget#showDomSelect to 
# <tt>false</tt>.
# 
# By default, DateWidget assumes you want the year field to be a freeform text 
# field. But if you would rather use a select widget, set 
# DateWidget#textEntryYear to <tt>false</tt>.
class DateWidget
	def DateWidget.months
    months = [ "January", "February", "March", "April", "May", "June", "July",
							 "August", "September", "October", "November", "December" ]
	end

	attr_accessor :showDomSelect, :textEntryYear

	# [name] Name of the field.
	# [date] Sets the pre-selected date; leave this is nil if you don't want any 
	#        date pre-selected.
	def initialize(name = 'date', date = nil)
		@name = name
		@date = date
    @selectedMonth = @date != nil ? @date.mon : nil
 	  @selectedDom = @date != nil ? @date.mday : ""
   	@selectedYear = @date != nil ? @date.year : ""
   	@showDomSelect = true
   	@textEntryYear = false
	end

	def monthSelect
    select = HTML::Select.new({ 'name' => "#{@name}.month" })
		select.selected = @selectedMonth
    monthCount = 1
		self.class.months.each { |month|
      select.addOption(monthCount, month)
      monthCount += 1
    }
		select
	end

	def domSelect
		select = HTML::Select.new({ 'name' => "#{@name}.dom" })
		select.selected = @selectedDom
		1.upto(31) { |dom| select.addOption dom }
		select
	end

	def yearSelect
		select = HTML::Select.new({ 'name' => "#{@name}.year" })
		select.selected = @selectedYear
		2000.upto(2010) { |year| select.addOption year }
		select
	end
	
	def yearInput
		HTML::Input.new({ 'name' => "#{@name}.year", 'value' => @selectedYear,
				'size' => '4' })
	end

	# Returns an HTML string for use in a form.
	def toHTML
		widget = HTML.new
		widget << monthSelect
		widget << domSelect if @showDomSelect
		if @textEntryYear
			widget << yearInput
		else
			widget << yearSelect
		end
    widget.toHTML
	end
end
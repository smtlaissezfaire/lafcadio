require 'lafcadio/test'
require 'date'
require 'lafcadio/query'
require '../test/mock/domain/InternalClient'
require '../test/mock/domain/Invoice'
require '../test/mock/domain/User'

class TestCompare < LafcadioTestCase
	def testComparators
		comparators = {
			Query::Compare::LESS_THAN => '<',
			Query::Compare::LESS_THAN_OR_EQUAL => '<=',
			Query::Compare::GREATER_THAN_OR_EQUAL => '>=',
			Query::Compare::GREATER_THAN => '>'
		}
		comparators.each { |compareType, comparisonSymbol|
			dc = Query::Compare.new('date', Date.new(2003, 1, 1), Invoice,
					compareType)
			assert_equal( "invoices.date #{ comparisonSymbol } '2003-01-01'",
			              dc.toSql )
		}
	end
	
	def testDbFieldName
		compare = Query::Compare.new( 'text1', 'foobar', XmlSku,
		                              Query::Compare::LESS_THAN )
		assert_equal( "some_other_table.text_one < 'foobar'", compare.toSql )
	end

	def testFieldBelongingToSuperclass
		condition = Query::Compare.new('standard_rate', 10, InternalClient,
				Query::Compare::LESS_THAN)
		assert_equal( 'clients.standard_rate < 10', condition.toSql )
	end

	def test_handles_dobj_that_doesnt_exist
		condition = Query::Compare.new( 'client',
		                                DomainObjectProxy.new( Client, 10 ),
																		Invoice, Query::Compare::LESS_THAN )
		assert_equal( 'invoices.client < 10', condition.toSql )
		assert_equal( 0, @mockObjectStore.getSubset( condition ).size )
		condition2 = Query::Compare.new( 'client', 10, Invoice,
		                                 Query::Compare::LESS_THAN )
		assert_equal( 'invoices.client < 10', condition2.toSql )
		assert_equal( 0, @mockObjectStore.getSubset( condition2 ).size )		
	end
	
	def testLessThan
		condition = Query::Compare.new(
				User.sql_primary_key_name, 10, User, Query::Compare::LESS_THAN)
		assert_equal( 'users.pkId < 10', condition.toSql )
	end

	def testMockComparatorAndNilValue
		invoice = Invoice.getTestInvoice
		invoice.date = nil
		dc = Query::Compare.new(
				'date', Date.today, Invoice, Query::Compare::LESS_THAN)
		assert !dc.objectMeets(invoice)
	end

	def testMockComparators
		date1 = Date.new(2001, 1, 1)
		date2 = Date.new(2002, 1, 1)
		date3 = Date.new(2003, 1, 1)
		invoice = Invoice.getTestInvoice
		invoice1 = invoice.clone
		invoice1.date = date1
		invoice2 = invoice.clone
		invoice2.date = date2
		invoice3 = invoice.clone
		invoice3.date = date3
		dc1 = Query::Compare.new(
				'date', date2, Invoice, Query::Compare::LESS_THAN)
		assert dc1.objectMeets(invoice1)
		assert !dc1.objectMeets(invoice2)
		assert !dc1.objectMeets(invoice3)
		dc2 = Query::Compare.new(
				'date', date2, Invoice,
				Query::Compare::LESS_THAN_OR_EQUAL)
		assert dc2.objectMeets(invoice1)
		assert dc2.objectMeets(invoice2)
		assert !dc2.objectMeets(invoice3)
		dc3 = Query::Compare.new(
				'date', date2, Invoice,
				Query::Compare::GREATER_THAN)
		assert !dc3.objectMeets(invoice1)
		assert !dc3.objectMeets(invoice2)
		assert dc3.objectMeets(invoice3)
		dc4 = Query::Compare.new(
				'date', date2, Invoice,
				Query::Compare::GREATER_THAN_OR_EQUAL)
		assert !dc4.objectMeets(invoice1)
		assert dc4.objectMeets(invoice2)
		assert dc4.objectMeets(invoice3)
	end

	def testNumericalSearchingOfaLinkField
		condition = Query::Compare.new('client', 10, Invoice,
				Query::Compare::LESS_THAN)
		assert_equal( 'invoices.client < 10', condition.toSql )
	end
end
# Lafcadio is an object-relational mapping library for Ruby and MySQL. Its
# design has a few aspects in mind:
# * The importance of unit-testing. Lafcadio includes a MockObjectStore which
#   can take the place of the ObjectStore for unit tests, so you can test
#   complex database-driven logic. Committing domain objects, running queries,
#   and even triggers can all be written in the Lafcadio level, meaning that
#   they can all be tested without hitting a live database.
# * Dealing with databases in the wild. Lafcadio excels at grappling with
#   pre-existing database schemas and all the odd ways the people use databases
#   in the wild. It requires very little from your schema, except for the fact
#   that each table needs a single numeric primary key. It makes many
#   assumptions about your naming conventions, but these assumptions can all be
#   overridden.
#
# First-time users are recommended to read the tutorial at
# http://lafcadio.rubyforge.org/tutorial.html.

module Lafcadio
	Version = "0.7.2"

	require 'lafcadio/dateTime'
	require 'lafcadio/depend'
	require 'lafcadio/domain'
	require 'lafcadio/mock'
	require 'lafcadio/objectField'
	require 'lafcadio/objectStore'
	require 'lafcadio/query'
	require 'lafcadio/schema'
	require 'lafcadio/util'
end
# encoding:utf-8
#--
# The MIT License (MIT)
#
# Copyright (c) 2015, The Gamera Development Team. See the COPYRIGHT file at
# the top-level directory of this distribution and at
# http://github.com/gamera-team/gamera/COPYRIGHT.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#++

require 'sequel'

module Gamera
  module Utils
    # Cleans a database by truncating the tables
    #
    # Usage:
    #
    #   Gamera::Utils::DatabaseCleaner.new(connection).clean
    #
    # Or:
    #
    #   Gamera::Utils::DatabaseCleaner.new(connection, tables).clean
    #
    # +connection+ is a Sequel database connection.
    # +tables+ is an array of table names (string or symbol).
    #
    # If +tables+ is given, only the tables supplied
    # will be truncated. If +tables+ is not given,
    # all tables in the database will be truncated.
    class DatabaseCleaner
      def initialize(connection, tables = nil)
        @db = connection
        @tables = tables || all_table_names
      end

      # Removes all data from the initialized tables.
      # If no tables were given, removes all data from
      # all tables in the database.
      #
      # Cleans via truncation.
      def clean
        tables.each do |table|
          db[table].truncate
        end
        nil
      end

      private

      attr_reader :db, :tables

      def all_table_names
        db.tables
      end
    end
  end
end

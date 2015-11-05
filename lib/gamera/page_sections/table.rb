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

require 'capybara'

module Gamera
  module PageSections
    # This class represents a table on a web page. For example, if you had
    # a page like
    #
    #   <html>
    #     <body>
    #       <p>Example table</p>
    #       <table>
    #         <tr>
    #           <th>Item</th>
    #           <th>Wholesale Cost</th>
    #           <th>Retail Cost</th>
    #           <th></th>
    #           <th></th>
    #         </tr>
    #         <tr>
    #           <td>Red Hat</td>
    #           <td>2.00</td>
    #           <td>15.00</td>
    #           <td><a href="/item/12/edit">Edit</a></td>
    #           <td><a href="/item/12/delete">Delete</a></td>
    #         </tr>
    #         <tr>
    #           <td>Skull cap</td>
    #           <td>2.00</td>
    #           <td>27.00</td>
    #           <td><a href="/item/1/edit">Edit</a></td>
    #           <td><a href="/item/1/delete">Delete</a></td>
    #         </tr>
    #       </table>
    #     </body>
    #   </html>
    #
    # you could include this in a page object class like so:
    #
    #   class HatPage < Gamera::Page
    #     include Forwardable
    #     include Gamera::PageSections
    #
    #     attr_reader :registration_form, :table
    #
    #     def initialize
    #       super(path_join(BASE_URL, '/hat'), %r{hat})
    #
    #       headers = ['Item', 'Wholesale Cost', 'Retail Cost']
    #       @registration_form = Table.new(headers: headers, row_name:hat,
    #                                      name_column: 'Item')
    #       def_delegators :hat_table,
    #                      :hat, :hats,
    #                      :has_hat?, :has_hats?,
    #                      :edit_hat, :delete_hat
    #     end
    #   end
    #
    class Table < DelegateClass(Capybara::Node::Element)
      include Capybara::DSL

     # @param headers [Array] An array of the strings from the tables header row
      # @param row_name [String] A label that can be used to create more readable versions of general row methods
      # @param plural_row_name [String] Plural form of [row_name]
      # @param name_column [String] The column heading for the column which contains each row's name
      # @param row_css [String] The CSS selector which is used to find individual rows in the table
      # @param row_class [Class] The class which will represent a table row
      # @param row_editor [Class] A class which defines the edit behavior for a row
      # @param row_deleter [Class] A class which defines the edit behavior for a row
      def initialize(headers:,
                     row_name:,
                     plural_row_name: nil,
                     name_column: 'Name',
                     row_css: 'tr + tr', # all tr's except the first one (which is almost always a table header)
                     row_class: TableRow,
                     row_editor: RowEditor.new,
                     row_deleter: RowDeleter.new
                    )
        @row_css = row_css
        @headers = headers
        @row_class = row_class
        @row_editor = row_editor
        @row_deleter = row_deleter
        @row_name = row_name
        @plural_row_name = plural_row_name
        @name_column = name_column.downcase.gsub(' ', '_').gsub(/[^a-z0-9_]+/, '')

        add_custom_function_names
      end

      # Retrieves an array of rows from the table
      #
      # @return [Array] An array of row_class objects
      def rows
        has_rows?
        all(row_css).map { |r| row_class.new(r, headers) }
      end

      # Finds and returns a row from the table
      #
      # @param name [String] [RegExp] The name to look for in the table's specified name column.
      # @return [row_class] A row_class object that has the matching name or nil
      def row_named(name)
        if name.is_a? String
          rows.detect { |r| r.send(name_column) == name } if has_row?(name)
        elsif name.is_a? Regexp
          rows.detect { |r| name.match r.send(name_column) } if has_row?(name)
        end
      end

      # Checks for the existence of a row with the given name
      #
      # @param name [String] The name to look for in the table's specified name column.
      # @return [Boolean] True if a row with the specified name is found, false
      # otherwise
      def has_row?(name)
        page.has_selector?(row_css, text: name)
      end

     # Checks for the absence of a row with the given name
     #
     # @param name [String] The name to look for in the table's specified name column.
     # @return [Boolean] False if a row with the specified name is found, true
     # otherwise
      def has_no_row?(name)
        page.has_no_selector?(row_css, text: name)
      end

      # Checks to see if the table has any rows
      #
      # @return [Boolean] True if the row selector is found, false otherwise
      def has_rows?
        has_selector?(row_css)
      end

      # Checks to see if the table has no rows
      #
      # @return [Boolean] False if the row selector is found, true otherwise
      def has_no_rows?
        has_no_selector?(row_css)
      end

      # Delete all of the rows from the table
      def delete_all_rows
        while has_rows?
          r = rows.first.send(name_column)
          delete_row(r)
          has_row?(r)
        end
      end

      # Start the delete process for the row matching the specified name
      def delete_row(name)
        row_deleter.delete(row_named(name))
      end

      # Start the edit process for the row matching the specified name
      def edit_row(name)
        row_editor.edit(row_named(name))
      end

      private

      attr_reader :headers, :row_css, :row_name, :name_column, :row_class,
        :row_editor, :row_deleter

      def add_custom_function_names
        row_name = @row_name # The attr_reader wasn't working here
        plural_row_name = @plural_row_name
        rows_name = plural_row_name ? plural_row_name.to_sym : "#{row_name}s".to_sym
        has_row_name = "has_#{row_name}?".to_sym
        has_no_row_name = "has_no_#{row_name}?".to_sym
        has_rows_name = plural_row_name ? "has_#{plural_row_name}?".to_sym : "has_#{row_name}s?".to_sym
        has_no_rows_name = plural_row_name ? "has_no_#{plural_row_name}?".to_sym : "has_no_#{row_name}s?".to_sym
        delete_all_rows_name = plural_row_name ? "delete_all_#{plural_row_name}".to_sym : "delete_all_#{row_name}s".to_sym
        delete_row_name = "delete_#{row_name}".to_sym
        edit_row_name = "edit_#{row_name}".to_sym

        self.class.instance_eval do
          alias_method rows_name, :rows
          alias_method has_row_name, :has_row?
          alias_method has_no_row_name, :has_no_row?
          alias_method has_rows_name, :has_rows?
          alias_method has_no_rows_name, :has_no_rows?
          alias_method delete_all_rows_name, :delete_all_rows
          alias_method delete_row_name, :delete_row
          alias_method edit_row_name, :edit_row
          alias_method row_name, :row_named
        end
      end


    end

    # Default class used to represent a row in a table
    class TableRow < DelegateClass(Capybara::Node::Element)
      # @param row_css [String] The css selector for the row
      # @param headers [Array] An array of the strings from the tables header row
      def initialize(row_css, headers)
        super(row_css)

        headers.each_with_index do |header, i|
          cell_name = header.downcase.gsub(' ', '_').gsub(/[^a-z0-9_]+/, '')
          self.class.send(:define_method, cell_name) do
            find("td:nth-child(#{i + 1})").text
          end
        end
      end
    end

    # Wrapper class for row edit action
    class RowEditor
      def edit(table_row)
        table_row.find_link('Edit').click
      end
    end

    # Wrapper class for row delete action
    class RowDeleter
      def delete(table_row)
        table_row.find_link('Delete').click
      end
    end
  end
end

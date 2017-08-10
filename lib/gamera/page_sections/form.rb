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
    # This class represents an html form on a web page. For example, if you had
    # a page like
    #
    #   <html>
    #   <body>
    #     <h2>Example form</h2>
    #     <form action='/user/register'>
    #       <label for="name">Name</label><input type="text" name="name" value="" id="name">
    #       <label for="email">Email</label><input type="text" name="email" value="" id="email">
    #       <label for="password">Password</label><input type="text" name="password" value="" id="password">
    #
    #       <input type="button" name="Register" id="save_button">
    #       <input type="button" name="Cancel" id="cancel_button">
    #     </form>
    #   </body>
    #   </html>
    #
    # you could include this in a page object class like so:
    #
    #   class RegistrationPage < Gamera::Page
    #     include Forwardable
    #
    #     attr_reader :registration_form, :table
    #
    #     def initialize
    #       super(path_join(BASE_URL, '/registration/new'), %r{registration/new$})
    #
    #       form_fields = {
    #         name: 'Name',
    #         email: 'Email',
    #         password: 'Password'
    #       }
    #
    #       @registration_form = Gamera::PageSections::Form.new(form_fields)
    #       def_delegators :registration_form, *registration_form.field_method_names
    #     end
    #
    #     def register
    #       find_button('Register').click
    #     end
    #
    #     def cancel
    #       find_button('Cancel').click
    #     end
    #   end
    #
    class Form
      include Capybara::DSL

      attr_accessor :fields, :field_method_names

      def initialize(fields)
        @fields = fields
        @field_method_names = []
        define_field_methods
      end

      # Utility method to populate the form based on a hash of field names and
      # values
      #
      # @param fields [Hash] The keys are the [field_name]s and the values are the values to which the fields are to be set.
      def fill_in_form(fields)
        fields.each do |field, value|
          f = send("#{field}_field")
          if f.tag_name == "select"
            Array(value).each { |val| f.select(val) }
          else
            f.set(value)
          end
        end
      end

      private

      # Creates methods for the specified form fields of the form "<field_name>_field"
      # (based on the results of [define_field_name]) that can be called to
      # interact with form controls on the web page
      def define_field_methods
        if fields.is_a?(Array)
          fields.each do |field_label|
            field = field_label.downcase.tr(' ', '_').gsub(/\W/, '').to_sym
            field_method_name = define_field_name(field)
            define_field_method(field_method_name, field_label)
          end
        elsif fields.is_a?(Hash)
          fields.each do |field, field_string|
            field_method_name = define_field_name(field)
            define_field_method(field_method_name, field_string)
          end
        end
      end

      # converts the provided field string into a suitable method name for
      # [define_field_methods] to use
      #
      # @param field [String] The user-readable name of a control on an html form
      def define_field_name(field)
        (field.to_s + '_field').to_sym.tap do |field_method_name|
          field_method_names << field_method_name
        end
      end

      # Defines an instance method named <field_method_name> for a given field
      #
      # @param field_method_name [String] Ruby-syntax-friendly name for the method being defined
      # @param field_string [String] The user-readable name or selector for the html form control
      def define_field_method(field_method_name, field_string)
        field_string = field_string.chomp(':')
        self.class.send(:define_method, field_method_name) do
          label_before_field_xpath = "//label[contains(., '#{field_string}')]/following-sibling::*[local-name() = 'input' or local-name() = 'textarea' or local-name() = 'select'][1]"
          label_after_field_xpath = "//label[contains(., '#{field_string}')]/preceding-sibling::*[local-name() = 'input' or local-name() = 'textarea' or local-name() = 'select'][1]"
          if has_selector?(:field, field_string)
            find_field(field_string)
          elsif has_xpath?(label_before_field_xpath)
            find(:xpath, label_before_field_xpath)
          else
            find(:xpath, label_after_field_xpath)
          end
        end
      end
    end
  end
end

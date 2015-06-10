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

require 'forwardable'

module Gamera
  # Builders provide a generic, standard interface for creating/setting
  # data in an app.
  #
  # For easy creation of a builder use the +with_options()+ class
  # builder method. For example:
  #
  #     class UserBuilder < Builder.with_options(:name, :bday, :nickname)
  #       def build
  #         User.create!(name: name, bday: bday, nickname: nickname)
  #       end
  #     end
  #
  # The created builder will automatically have methods to set each of the
  # options. In the example above the +UserBuilder#with_nickname+ method
  # will return a new +UserBuilder+ that has the specified nickname.
  #
  #     UserBuilder.new
  #       .with_nickname("shorty")
  #       .result
  #       #=> User(name: nil, bday: nil, nickname: "shorty")
  #
  # Sometimes the way you refer to values inside the builder may be
  # different than how clients do. In that case, builders can define
  # setter methods that use terminology that matches the client's point
  # of view.
  #
  #     class UserBuilder < Builder.with_options(:name, :bday)
  #       def born_on(a_date)
  #         refine_with bday: a_date
  #       end
  #     end
  #
  # Default values can be specified using the +default_for+ class
  # method.
  #
  #     class UserBuilder < Builder.with_options(:name, :bday)
  #       default_for :name, "Jane"
  #       default_for :bday { Time.now }
  #     end
  #
  # You can handle type conversions using coercion methods.
  #
  #     class UserBuilder < Builder.with_options(:name, :bday)
  #       def name_coercion(new_name)
  #         new_name ? new_name.to_s : "Bob"
  #       end
  #     end
  #
  # To use this builder:
  #
  #    UserBuilder.new
  #      .born_on(25.years.ago)
  #      .result
  #    #=> User(name: "Bob", bday: #<Date: Sat, 09 Dec 1989>)
  #
  # or
  #
  #    UserBuilder.new
  #      .with_bday(25.years.ago)
  #      .result
  #    #=> User(name: "Bob", bday: #<Date: Sat, 09 Dec 1989>)
  #
  # or
  #
  #    UserBuilder.new(bday: 25.years.ago)
  #      .result
  #    #=> User(name: "Bob", bday: #<Date: Sat, 09 Dec 1989>)
  class Builder
    extend Forwardable

    # One way to create builders.
    #
    #    b = Builder.create_with(name: "Bob", bday: 25.years.ago) do
    #      User.create!(name: name, bday: bday)
    #    end
    #
    #    b.build
    #    #=> User(name: "Bob", bday: #<Date: Sat, 09 Dec 1989>)
    def self.create_with(spec, &block)
      struct = Struct.new(*(spec.keys)) do
        def initialize(options = {})
          super
          options.each { |opt, value| self[opt] = value }
        end

        def with(options, &block)
          new_struct = dup
          options.each { |opt, value| new_struct[opt] = value }
          if block_given?
            new_struct.class.class_eval do
              define_method :build, &block
            end
          end
          new_struct
        end

        members.each do |opt|
          define_method "with_#{opt}" do |value, &inner_block|
            with(opt => value, &inner_block)
          end
        end

        define_method :build, &block
      end

      struct.new spec
    end

    # Module to extend the Builder DSL
    module Dsl
      # Sets the default value of an option
      #
      # @param option_name [String] Name of the builder option
      # @param val [Object] the simple default value of the option
      # @param gen [Block] block that returns default values
      #
      # Yields self to block (+gen+) if a block is provided. Return
      # value will be the default value.
      def default_for(option_name, val = nil, &gen)
        gen ||= ->(_) { val }

        prepend(Module.new do
          define_method :"#{option_name}_coercion" do |v|
            super v.nil? ? gen.call(self) : v
          end
        end)
      end
    end

    extend Dsl

    # Another way to create builders.
    #
    # For easy creation of a builder use the +with_options()+ class
    # builder method. For example:
    #
    #     class UserBuilder < Builder.with_options(:name, :bday, :nickname)
    #       def build
    #         User.create!(name: name, bday: bday, nickname: nickname)
    #       end
    #     end
    #
    # The created builder will automatically have methods to set each of the
    # options. In the example above the +UserBuilder#with_nickname+ method
    # will return a new +UserBuilder+ that has the specified nickname.
    #
    #     UserBuilder.new
    #       .with_nickname("shorty")
    #       .result
    #       #=> User(name: nil, bday: nil, nickname: "shorty")
    #
    def self.with_options(*option_names)
      init_arg_list = option_names.map { |o| "#{o}: nil" }.join(', ')
      args_to_ivars = option_names.map { |o| "@#{o} = #{o}_coercion(#{o})" }.join('; ')

      Class.new(self) do
        module_eval <<-METH
        def initialize(#{init_arg_list})  # def initialize(tags: nil, name: nil)
        #{args_to_ivars}                #   @tags = tags_coercion(tags); @name = name_coercion(name)
                       super()                         #   super()
        end                               # end
        METH

        # +with_...+ methods
        option_names.each do |name|
          define_method(:"with_#{name}") do |new_val, *extra|
            val = if extra.any?
                    # called with multiple params, eg (p1,p2,p3,...), so
                    # package those as an array and pass them in
                    [new_val] + extra
                  else
                    # called with single param
                    new_val
                  end

            refine_with(name => val)
          end
        end

        protected

        attr_reader(*option_names)

        define_method(:options) do
          Hash[option_names.map { |o| [o, send(o)] }]
        end

        option_names.each do |o_name|
          define_method(:"#{o_name}_coercion") { |new_val| new_val }
        end
      end
    end

    # The object built by this builder
    def result
      @result ||= build
    end

    # Executes the builder
    #
    # @note Don't call this method directly, use +#result+ instead.
    def build
      fail NotImplementedError
    end

    def_delegator :self, :build, :call

    # Returns a clone of this object but with options listed in
    # +alterations+ updated to match.
    def refine_with(alterations)
      self.class.new options.merge(alterations)
    end
  end
end

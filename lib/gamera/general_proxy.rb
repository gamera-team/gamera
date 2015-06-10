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

module Gamera
  # This implements a specific sub-pattern of the proxy pattern. Rather than
  # knowing about a specific class's methods, it will add a singleton method to
  # a given object for each method defined by that method's class or the
  # method's class and up through a specified class in the ancestor chain.
  #
  # Important Note: This module must be *prepended* rather than *included* for
  # +self+ to refer to the class containing the module. If the proxying isn't
  # happening, this is likely the problem.
  #
  # Usage example:
  # if you are testing a class +Foo+ with Capybara and you'd like to take a
  # screenshot everytime a method in that class is called
  #   class Foo
  #     prepend Gamera::GeneralProxy
  #
  #     def my_method
  #       # do something interesting in a browser
  #     end
  #
  #     def my_other_method
  #       # do something else interesting in a browser
  #     end
  #   end
  #
  # In the spec file
  #
  #   describe Foo do
  #     let(:foo) { Foo.new }
  #     it "does something"
  #     foo.start_proxying(->(*args)
  #       {Capybara::Screenshot.screenshot_and_save_page
  #         super(*args)})
  #     foo.my_method # => screenshot taken & method called
  #     foo.my_other_method # => screenshot taken & method called
  #     foo.stop_proxying
  #     foo.my_method # => *crickets* (aka method called)
  #     foo.my_other_method # => *crickets*
  #     ...
  module GeneralProxy
    def start_proxying(a_lambda = ->(*args) { super(*args) }, top_class = self.class)
      @top_class = top_class
      ancestors = self.class.ancestors
      proxy_target_classes = ancestors[1..ancestors.index(top_class)]
      proxy_target_classes.each do |klass|
        klass.instance_methods(false).each do |method|
          define_singleton_method(method, a_lambda)
        end
      end
    end

    def stop_proxying
      start_proxying(-> (*args) { super(*args) }, @top_class)
    end
  end
end

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

require_relative '../../../lib/gamera/general_proxy'

# Use this to test the proxy's handling of class hierarchy methods
class ProxyTestClass
  def foo(an_argument)
    "foo(#{an_argument})"
  end

  def bar
    'just bar'
  end
end

# Use this to test everything else
class KidOfProxyTestClass < ProxyTestClass
  prepend Gamera::GeneralProxy

  # not actually private
  def my_own_public_idaho(*args)
    args.empty? ? 'IDAHO' : "IDAHO: #{args}"
  end

  private

  def my_own_private_idaho(*args)
    args.empty? ? 'PRIVATE IDAHO' : "PRIVATE IDAHO: #{args}"
  end
end

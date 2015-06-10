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

require_relative '../../spec_helper'
require_relative 'proxy_test_class'

describe Gamera::GeneralProxy do
  let(:kptc) { KidOfProxyTestClass.new }

  it 'is off by default' do
    expect(kptc.singleton_methods).not_to include(:my_own_public_idaho)
  end

  it 'can be turned on and off' do
    expect(kptc.singleton_methods).not_to include(:my_own_public_idaho)
    expect(kptc.my_own_public_idaho).to eq 'IDAHO'
    kptc.start_proxying(->(*args) { 'OMAHA & ' + super(*args) })
    expect(kptc.singleton_methods).to include(:my_own_public_idaho)
    expect(kptc.my_own_public_idaho).to eq 'OMAHA & IDAHO'
    kptc.stop_proxying
    expect(kptc.my_own_public_idaho).to eq 'IDAHO'
  end

  it "actually proxies the class's methods'" do
    kptc.start_proxying(->(*_args) { return 'consider yourself proxied!'; super })
    expect(kptc.my_own_public_idaho).to eq 'consider yourself proxied!'
  end

  it 'only proxies including class by default' do
    kptc.start_proxying(->(*args) { 'OMAHA & ' + super(*args) })
    expect(kptc.singleton_methods).to include(:my_own_public_idaho)
    expect(kptc.singleton_methods).not_to include(:foo)
    expect(kptc.singleton_methods).not_to include(:bar)
    kptc.stop_proxying
  end

  it 'can proxy up the class hierarchy' do
    kptc.start_proxying(->(*args) { 'OMAHA & ' + super(*args) }, ProxyTestClass)
    expect(kptc.singleton_methods).to include(:my_own_public_idaho)
    expect(kptc.singleton_methods).to include(:foo)
    expect(kptc.singleton_methods).to include(:bar)
    kptc.stop_proxying
  end
end

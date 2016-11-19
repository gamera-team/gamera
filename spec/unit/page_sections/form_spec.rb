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

require_relative '../../resources/simple_form/simple_form'
require_relative '../../resources/simple_form/simple_form_page'
require_relative '../../spec_helper'

describe 'SimpleFormPage' do
  before :all do
    set_app SimpleForm
  end

  it 'submits the form' do
    form_page = SimpleFormPage.new

    form_page.visit
    form_page.fill_in_form(text: 'Entered Text', selection: 'C', multipleselection: %w(A C))
    form_page.submit

    expect(form_page.text).to eq("You entered 'Entered Text', you selected 'C' from the single select field, you selected 'A,C' from the multiple select field, and you did not check the checkbox.")
  end

  it 'fills in a checkbox properly' do
    form_page = SimpleFormPage.new

    form_page.visit
    form_page.fill_in_form(multipleselection: ['A'], checkbox: true)
    form_page.submit
    expect(form_page.text).to include('you checked the checkbox.')
  end
end

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
require_relative '../../resources/simple_tables/simple_tables'
require_relative '../../../spec/resources/simple_tables/simple_tables_page'

describe 'SimpleTablesPage' do
  let(:tables_page) { SimpleTablesPage.new }

  before :all do
    set_app SimpleTables
  end

  it 'finds an edit link' do
    tables_page.visit
    tables_page.edit_fruit('Apple')
    expect(tables_page.text).to eq("Action 'edit' is not available for Apple")
  end

  it 'finds a custom delete link' do
    tables_page.visit
    tables_page.delete_vegetable('Brussels Sprouts')
    expect(tables_page.text).to eq("Action 'delete' is not available for Brussels Sprouts")
  end

  it 'defines columns' do
    tables_page.visit
    expect(tables_page.fruit('Pear').color).to eq('Green')
  end

  it 'successfully takes a custom row object' do
    tables_page.visit
    tables_page.vegetable('Broccoli').select_row
    tables_page.first('input').synchronize do
      expect(tables_page).to have_checked_field('broccoli')
    end
  end

  it 'finds the correct row when there are other rows with a similar name' do
    tables_page.visit
    expect(tables_page.fruit('Grape').color).to eq('Purple')
  end

  it 'finds a row based on a regex' do
    tables_page.visit
    expect(tables_page.fruit(/Grape.+/).color).to eq('Pink')
  end

  it 'identifies whether a row exists' do
    tables_page.visit
    expect(tables_page).to have_fruit('Grape')
  end

  it 'identifies whether a row does not exist' do
    tables_page.visit
    expect(tables_page).to have_no_fruit('Pineapple')
  end

  it 'identifies when a table has no rows' do
    tables_page.visit
    expect(tables_page).not_to have_no_fruits
  end
end

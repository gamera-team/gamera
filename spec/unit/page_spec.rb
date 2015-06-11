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

require_relative '../spec_helper'
require_relative '../../spec/resources/simple_site/home_page'
require_relative '../../spec/resources/simple_site/redirect_page'
require_relative '../../spec/resources/simple_site/hit_counter_page'
require_relative '../resources/simple_site/simple_site'

class TextNotFoundError < StandardError; end

describe 'Page' do
  let(:hit_counter_page) do
    h = HitCounterPage.new
  end

  before :each do
    set_app SimpleSite.new
  end

  it 'catches a redirect' do
    redirect_page = RedirectPage.new
    expect { redirect_page.visit }.to raise_error
    expect(redirect_page).not_to be_displayed

    home_page = HomePage.new
    expect(home_page).to be_displayed
  end

  it 'ignores a redirect if told to' do
    redirect_page = RedirectPage.new
    expect { redirect_page.visit(false) }.not_to raise_error
  end

  it 'refreshes until a condition is met and then stops refreshing' do
    hit_counter_page.visit

    hit_counter_page.with_refreshes(5) do
      expect(hit_counter_page).to have_text 'You have visited this page 4 times'
    end

    # It should have stopped after it got to four visits
    expect(hit_counter_page).to have_text 'You have visited this page 4 times'
  end

  it 'fails after the right number of visits if the condition is not ever met' do
    expect do
      hit_counter_page.with_refreshes(2, TextNotFoundError) do
        fail TextNotFoundError unless hit_counter_page.has_text? 'This text does not ever appear'
      end
    end.to raise_exception(TextNotFoundError)

    expect(hit_counter_page).to have_text 'You have visited this page 3 times' # Two refreshes means three visits total
  end
end

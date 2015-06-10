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

require 'sinatra/base'

class SimpleSite < Sinatra::Base
  def initialize
    super

    reset_hit_counter
  end

  get '/' do
    erb :home
  end

  get '/redirect' do
    redirect to '/'
  end

  get '/hit_counter' do
    ENV['SIMPLE_SITE_HITS'] = (ENV['SIMPLE_SITE_HITS'].to_i + 1).to_s
    erb :hit_counter
  end

  def reset_hit_counter
    ENV['SIMPLE_SITE_HITS'] = nil
  end

  run! if app_file == $PROGRAM_NAME
end

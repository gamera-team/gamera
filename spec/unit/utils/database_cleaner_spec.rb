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

require_relative '../../../lib/gamera/utils/database_cleaner'

module Gamera
  module Utils
    describe DatabaseCleaner do
      let(:connection) { double('Sequel DB', tables: all_tables) }
      let(:specified_tables) { [:users, :roles] }
      let(:unspecified_tables) { [:foos, :bars] }
      let(:all_tables) { specified_tables + unspecified_tables }

      shared_examples_for 'cleaner' do
        it 'cleans only the expected tables' do
          all_tables.each do |table_name|
            table = double(table_name)
            allow(connection).to receive(:[]).with(table_name).and_return(table)
            if expected_tables.include?(table_name)
              expect(table).to receive(:truncate)
            else
              expect(table).to_not receive(:truncate)
            end
          end
          subject.clean
        end
      end

      describe '#clean' do
        context 'with specified tables' do
          let(:expected_tables) { specified_tables }
          subject { DatabaseCleaner.new(connection, specified_tables) }

          it_behaves_like 'cleaner'
        end

        context 'without specified tables' do
          let(:expected_tables) { all_tables }
          subject { DatabaseCleaner.new(connection) }

          it_behaves_like 'cleaner'
        end
      end
    end
  end
end

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
require_relative '../../../lib/gamera/builder'
require_relative '../../../lib/gamera/builders/sequel_fixture_builder'
require_relative '../../../lib/gamera/utils/database_cleaner'

module Gamera
  module Builders
    describe SequelFixtureBuilder do
      let!(:without_environment_database_yml_db) { initialize_without_environment_database_yml_db }
      let!(:with_environment_database_yml_db) { initialize_with_environment_database_yml_db }
      let!(:without_environment_hash_db) { initialize_without_environment_hash_db }
      let!(:with_environment_hash_db) { initialize_with_environment_hash_db }

      shared_examples_for '#build' do
        let(:expected_tables) { expected_table_counts.keys }
        let(:unfixtured_id) { 1337 }

        subject do
          SequelFixtureBuilder.new(
            database_config: config,
            fixture_directory: fixtures,
            database_cleaner_options: opts
          )
        end

        it 'cleans the database before running' do
          expected_tables.each do |table|
            db[table].insert(id: unfixtured_id)
          end

          subject.build

          expected_tables.each do |table|
            expect(db[table].where(id: unfixtured_id)).to be_empty
          end
        end

        it 'populates the database with the given fixtures' do
          subject.build

          expected_table_counts.each do |table, count|
            expect(db[table].count).to eq count
          end
        end
      end

      shared_examples_for 'invalid database config' do
        subject { SequelFixtureBuilder.new(database_config: config) }

        it 'causes a DatabaseNotConfigured exception' do
          expect do
            subject.build
          end.to raise_error(Gamera::DatabaseNotConfigured, 'Unable to connect to database: Missing config for adapter, database, username')
        end
      end

      context 'with a database config file without environment keys' do
        let(:db) { without_environment_database_yml_db }
        let(:config) { database_yml_path('without_environment_database.yml') }
        let(:fixtures) { fixtures_path('without_environment_database_yml_fixtures') }
        let(:opts) { {} }
        let(:expected_table_counts) { { users: 3, blogs: 2, posts: 3, comments: 1 } }

        it_behaves_like '#build'
      end

      context 'with a database config file with environment keys' do
        let(:db) { with_environment_database_yml_db }
        let(:config) { database_yml_path('with_environment_database.yml') }
        let(:fixtures) { fixtures_path('with_environment_database_yml_fixtures') }
        let(:opts) { {} }
        let(:expected_table_counts) { { members: 2, roles: 3, members_roles: 3 } }

        it_behaves_like '#build'
      end

      context 'with a fixtures containing ERB markup' do
        let(:db) { without_environment_database_yml_db }
        let(:config) { database_yml_path('without_environment_database.yml') }
        let(:fixtures) { fixtures_path('with_erb_fixtures') }
        let(:opts) { {} }
        let(:expected_table_counts) { { users: 3, blogs: 2, posts: 3, comments: 1 } }

        it_behaves_like '#build'

        it 'parses the ERB correctly' do
          SequelFixtureBuilder.new(
            database_config: config,
            fixture_directory: fixtures,
            database_cleaner_options: opts
          ).build
          expect(db[:users].where(last_name: 'Skywalker').count).to eq 2
        end
      end

      context 'with an invalid database config file' do
        let(:config) { database_yml_path('invalid_database.yml') }

        it_behaves_like 'invalid database config'
      end

      context 'with a database config hash without environment keys' do
        let(:db) { without_environment_hash_db }
        let(:config) { DatabaseHelper::WITHOUT_ENVIRONMENT_HASH_CONFIG }
        let(:fixtures) { fixtures_path('without_environment_hash_fixtures') }
        let(:opts) { {} }
        let(:expected_table_counts) { { houses: 1, people: 2, residents: 2 } }

        it_behaves_like '#build'
      end

      context 'with a database config hash with environment keys' do
        let(:db) { with_environment_hash_db }
        let(:config) { DatabaseHelper::WITH_ENVIRONMENT_HASH_CONFIG }
        let(:fixtures) { fixtures_path('with_environment_hash_fixtures') }
        let(:opts) { {} }
        let(:expected_table_counts) { { widgets: 1, components: 2 } }

        it_behaves_like '#build'
      end

      context 'with an invalid database config hash' do
        let(:config) { DatabaseHelper::INVALID_HASH_CONFIG }

        it_behaves_like 'invalid database config'
      end

      context 'skipping the database cleaner' do
        let(:config) { DatabaseHelper::WITHOUT_ENVIRONMENT_HASH_CONFIG }
        let(:fixtures) { fixtures_path('without_environment_hash_fixtures') }
        let(:opts) { { skip: true } }

        subject do
          SequelFixtureBuilder.new(
            database_config: config,
            fixture_directory: fixtures,
            database_cleaner_options: opts
          )
        end

        it 'does not initialize and use the database cleaner' do
          expect(Utils::DatabaseCleaner).to_not receive(:new)
          subject.build
        end
      end

      context 'only cleaning certain tables with the database cleaner' do
        let(:config) { DatabaseHelper::WITHOUT_ENVIRONMENT_HASH_CONFIG }
        let(:fixtures) { fixtures_path('without_environment_hash_fixtures') }
        let(:opts) { { tables: %i[houses residents] } }

        let(:db) { subject.db }
        let!(:houses) { db[:houses] }
        let!(:people) { db[:people] }
        let!(:residents) { db[:residents] }

        subject do
          SequelFixtureBuilder.new(
            database_config: config,
            fixture_directory: fixtures,
            database_cleaner_options: opts
          )
        end

        it 'only cleans the given tables' do
          allow(db).to receive(:[]).with(:houses).and_return(houses)
          expect(houses).to receive(:truncate)
          allow(db).to receive(:[]).with(:residents).and_return(residents)
          expect(residents).to receive(:truncate)
          allow(db).to receive(:[]).with(:people).and_return(people)
          expect(people).to_not receive(:truncate)

          subject.build
        end
      end
    end
  end
end

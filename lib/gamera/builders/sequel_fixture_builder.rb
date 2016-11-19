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

require 'yaml'
require 'sequel'
require 'sequel-fixture'

module Gamera
  module Builders
    # A builder for loading YAML fixtures using a Sequel DB connection.
    #
    # Usage:
    #
    #   Gamera::Builders::SequelFixtureBuilder.new(
    #     database_config:          "/path/to/database.yml",
    #     fixture_directory:        "/path/to/fixtures/",
    #     database_cleaner_options: { skip: false, tables: ['users', 'messages'] }
    #   ).build
    #
    # Or:
    #
    #   Gamera::Builders::SequelFixtureBuilder.new.
    #     with_database_config("/path/to/database.yml").
    #     with_fixture_directory("/path/to/fixtures/").
    #     with_database_cleaner_options({ skip: false, tables: ['users', 'messages'] }).
    #     build
    #
    # Defaults:
    #   database_config:    ./config/database.yml
    #   fixture_directory:  ./spec/fixtures/ or ./test/fixtures/
    #   database_cleaner_options:
    #     skip:   false
    #     tables: (all tables in the database)
    #
    # So if you follow these defaults, you can simply do:
    #
    #   Gamera::Builders::SequelFixtureBuilder.new.build
    class SequelFixtureBuilder < Gamera::Builder.with_options(:database_config, :fixture_directory, :database_cleaner_options)
      DEFAULT_DATABASE_CONFIG        = './config/database.yml'.freeze
      DEFAULT_SPEC_FIXTURE_DIRECTORY = './spec/fixtures'.freeze
      DEFAULT_TEST_FIXTURE_DIRECTORY = './test/fixtures'.freeze

      # Truncates the database and imports the fixtures.
      # Returns a +Sequel::Fixture+ object, containing
      # hashes of all the fixtures by table name
      # (https://github.com/whitepages/sequel-fixture).
      def build
        # Truncate all tables
        unless skip_database_cleaner
          cleaner = Utils::DatabaseCleaner.new(db, database_cleaner_tables)
          cleaner.clean
        end

        fixture_path, fixture_dir = File.split(path_to_fixtures)

        Sequel::Fixture.path = fixture_path

        Sequel::Fixture.new(fixture_dir.to_sym, db)
      end

      # The +Sequel+ database connection.
      # Raises +Gamera::DatabaseNotConfigured+ if it fails
      # to initialize the database from the given config
      # or defaults.
      def db
        @db ||= self.class.db(database_config)
      end

      # Finds the full path to the fixtures directory.
      # Uses the given +fixture_directory+ if given.
      # Otherwise tries to use ./spec/fixtures or ./test/fixtures.
      #
      # Raises +Gamera::DatabaseNotConfigured+ if it cannot find
      def path_to_fixtures
        @path_to_fixtures ||= begin
          if fixture_directory && !fixture_directory.empty?
            unless File.exist?(fixture_directory)
              raise DatabaseNotConfigured, "Invalid fixture directory #{fixture_directory}"
            end
            fixture_directory
          elsif File.exist?(DEFAULT_SPEC_FIXTURE_DIRECTORY)
            DEFAULT_SPEC_FIXTURE_DIRECTORY
          elsif File.exist?(DEFAULT_TEST_FIXTURE_DIRECTORY)
            DEFAULT_TEST_FIXTURE_DIRECTORY
          else
            raise DatabaseNotConfigured, 'Unable to find fixtures to load'
          end
        end
      end

      private

      # The cache of +Sequel+ database connections by database config.
      # Raises +Gamera::DatabaseNotConfigured+ if it fails to initialize
      # the database from the given config
      def self.db(database_config)
        @db ||= {}
        @db[database_config || DEFAULT_DATABASE_CONFIG] ||= begin
          config = database_config_from_file(database_config) || database_config_from_hash(database_config) || database_config_from_default
          if config
            Sequel.connect(config)
          else
            raise DatabaseNotConfigured, 'Unable to connect to database'
          end
        end
      end

      # Attempts to load database config by interpretting the given
      # config as a string path to a YAML config file.
      #
      # Can accept a file with top-level keys matching environments,
      # like those found in Rails database.yml files,
      # in which case, it chooses the 'test' environment.
      #
      # Alternatively, it can accept a file with top-level keys matching
      # the database config keys.
      #
      # Database config keys are:
      # => adapter
      # => database
      # => username
      # => password (optional)
      # => host (optional)
      #
      # Returns hash containing the database config options
      # if possible, and nil if not.
      def self.database_config_from_file(config = nil)
        return nil unless config.is_a?(String) && File.exist?(config)

        db_config = begin
                      YAML.load_file(config)
                    rescue
                      nil
                    end
        return nil unless db_config

        database_config_from_hash(db_config)
      end

      # Attempts to load database config by interpretting the given
      # config as a hash with the config options.
      #
      # Can accept a hash with top-level keys matching environments,
      # like those found in Rails database.yml files,
      # in which case, it chooses the 'test' or :test environment.
      #
      # Alternatively, it can accept a hash with top-level keys matching
      # the database config keys.
      #
      # Database config keys are:
      # => adapter
      # => database
      # => username
      # => password (optional)
      # => host (optional)
      #
      # Returns hash containing the database config options
      # if possible, and nil if not.
      def self.database_config_from_hash(config = nil)
        return nil unless config.is_a?(Hash)

        db_config = if config.key?('test')
                      config['test']
                    elsif config.key?(:test)
                      config[:test]
                    else
                      config
                    end

        verify_database_config(db_config)

        db_config
      end

      # Attempts to load the database config from the default
      # location of ./config/database.yml if the file exists.
      #
      # Delegates to #database_config_from_file
      def self.database_config_from_default
        database_config_from_file(DEFAULT_DATABASE_CONFIG)
      end

      # Given a hash, confirms all required DB config fields are
      # present. Otherwise raises +Gamera::DatabaseNotConfigured+.
      #
      # Required fields (string or symbol):
      # => adapter
      # => database
      # => username
      def self.verify_database_config(db_config)
        db_config ||= {}
        missing_fields = [:adapter, :database, :username].reject do |field|
          db_config.key?(field) || db_config.key?(field.to_s)
        end
        unless missing_fields.empty?
          raise DatabaseNotConfigured, "Unable to connect to database: Missing config for #{missing_fields.join(', ')}"
        end
      end

      # Boolean from database_cleaner_options.
      # Defaults to +false+ if not set.
      def skip_database_cleaner
        database_cleaner_option(:skip, false)
      end

      # Array of table names from database_cleaner_options.
      # Defaults to +nil+, which is interpretted as "all tables".
      def database_cleaner_tables
        database_cleaner_option(:tables, nil)
      end

      # Retrieves options from the +database_cleaner_options+
      # hash, returning the given +default+ if the
      # database_cleaner_options don't exist, or the given
      # key (as a symbol or string) isn't set.
      def database_cleaner_option(symbol, default)
        options = database_cleaner_options || {}

        if options.key?(symbol)
          options[symbol]
        elsif options.key?(symbol.to_s)
          options[symbol.to_s]
        else
          default
        end
      end
    end
  end
end

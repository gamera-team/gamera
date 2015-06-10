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

require 'sqlite3'

module DatabaseHelper
  WITHOUT_ENVIRONMENT_HASH_CONFIG = {
    adapter: 'sqlite',
    database: 'file:without-environment-hash?mode=memory&cache=shared',
    username: 'root',
    password: nil
  }

  WITH_ENVIRONMENT_HASH_CONFIG = {
    test: {
      adapter: 'sqlite',
      database: 'file:with-environment-hash?mode=memory&cache=shared',
      username: 'root',
      password: nil
    }
  }

  INVALID_HASH_CONFIG = {
    anything_but_test: {
      adapter: 'sqlite',
      database: 'file:invalid-hash?mode=memory&cache=shared',
      username: 'root',
      password: nil
    }
  }

  def initialize_all_dbs
    initialize_without_environment_database_yml_db
    initialize_with_environment_database_yml_db
    initialize_without_environment_hash_db
    initialize_with_environment_hash_db
  end

  def initialize_without_environment_database_yml_db
    config = load_database_yml('without_environment_database.yml')
    db = Sequel.connect(config)

    if db.tables.empty?
      db.create_table :users do
        primary_key :id
        String :first_name
        String :last_name
        String :email
      end
      db.create_table :blogs do
        primary_key :id
        String :name
        Integer :user_id
      end
      db.create_table :posts do
        primary_key :id
        String :title
        String :body
        Integer :blog_id
      end
      db.create_table :comments do
        primary_key :id
        String :comment
        Integer :post_id
        Integer :user_id
      end
    else
      truncate(db)
    end
    db
  end

  def initialize_with_environment_database_yml_db
    config = load_database_yml('with_environment_database.yml')['test']
    db = Sequel.connect(config)

    if db.tables.empty?
      db.create_table :members do
        primary_key :id
        String :name
      end
      db.create_table :roles do
        primary_key :id
        String :name
      end
      db.create_table :members_roles do
        primary_key :id
        Integer :member_id
        Integer :role_id
      end
    else
      truncate(db)
    end
    db
  end

  def initialize_without_environment_hash_db
    db = Sequel.connect(WITHOUT_ENVIRONMENT_HASH_CONFIG)

    if db.tables.empty?
      db.create_table :people do
        primary_key :id
        String :first_name
        String :last_name
      end
      db.create_table :houses do
        primary_key :id
        String :street_address
        String :city
        String :state
        String :zip
      end
      db.create_table :residents do
        primary_key :id
        Integer :person_id
        Integer :house_id
      end
    else
      truncate(db)
    end
    db
  end

  def initialize_with_environment_hash_db
    db = Sequel.connect(WITH_ENVIRONMENT_HASH_CONFIG[:test])

    if db.tables.empty?
      db.create_table :widgets do
        primary_key :id
        String :name
      end
      db.create_table :components do
        primary_key :id
        String :name
        Integer :widget_id
      end
    else
      truncate(db)
    end
    db
  end

  def truncate(db)
    db.tables.each { |table| db[table].truncate }
  end

  def database_yml_path(filename)
    File.join(File.dirname(__FILE__), 'db', filename)
  end

  def load_database_yml(filename)
    YAML.load_file(database_yml_path(filename))
  end

  def fixtures_path(dirname)
    File.join(File.dirname(__FILE__), '..', 'fixtures', dirname)
  end
end

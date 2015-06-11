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

require 'capybara'
require_relative 'exceptions'

module Gamera
  # This is a base class which implements common methods for page object
  # classes.
  #
  # You can use this to create a Ruby class which wraps a web page, providing
  # an API for automating elements or processes on the page
  #
  # @example Page Object class for registration page
  #   class NewRegistrationPage < Gamera::Page
  #     def initialize
  #       @url = 'http://example.com/registration/new'
  #       @url_matcher = /registration\/new/
  #     end
  #
  #     # page elements
  #     def name_field
  #       find_field('Name')
  #     end
  #
  #     def email_field
  #       find_field('Email Address')
  #     end
  #
  #     def password_field
  #       find_field('Password')
  #     end
  #
  #     def password_confirmation_field
  #       find_field('Confirm Password')
  #     end
  #
  #     def instructions
  #     def instructions
  #       find('#instructions')
  #     end
  #
  #     # page processes
  #     def save
  #       find_button('Save').click
  #     end
  #
  #     def register_user(name:, email:, password:)
  #       name_field.set(name)
  #       email_field.set(email)
  #       password_field.set(password)
  #       password_confirmation_field.set(password)
  #       save
  #     end
  #   end
  #
  #   # This could be used in a test or automation script, e.g.
  #   ...
  #   reg_page = NewRegistrationPage.new
  #   reg_page.visit
  #   reg_page.register_user(name: 'Laurence Peltier',
  #                          email: 'lpeltier@example.com',
  #                          password: 'super_secret')
  #   ...
  #
  # @example Page class for general Rails page with flash messages
  #   class RailsPage < Gamera::Page
  #     def flash_error_css
  #       'div.flash.error'
  #     end
  #
  #     def flash_notice_css
  #       'div.flash.notice'
  #     end
  #
  #     def flash_error
  #       find(flash_error_css)
  #     end
  #
  #     def flash_notice
  #       find(flash_notice_css)
  #     end
  #
  #     def has_flash_message?(message)
  #       has_css?(flash_notice_css, text: message)
  #     end
  #
  #     def has_flash_error?(error)
  #       has_css?(flash_error_css, text: error)
  #     end
  #
  #     def has_no_flash_error?
  #       has_no_css?(flash_error_css)
  #     end
  #
  #     def has_no_flash_message?
  #       has_no_css?(flash_notice_css)
  #     end
  #
  #     def has_submission_problems?
  #       has_flash_error?('There were problems with your submission')
  #     end
  #
  #     def fail_if_submission_problems
  #       fail(SubmissionProblemsError, flash_error.text) if has_submission_problems?
  #     end
  #   end
  class Page
    include Capybara::DSL

    attr_reader :url, :url_matcher

    def initialize(url, url_matcher = nil)
      @url = url
      @url_matcher = url_matcher
    end

    # Open the page url in the browser specified in your Capybara configuration
    #
    # @param fail_on_redirect [Boolean] Whether to fail if the site redirects to a page that does not match the url_matcher regex
    # @raise [WrongPageVisited] if the site redirects to URL that doesn't match the url_matcher regex and fail_on_redirect is true
    def visit(fail_on_redirect = true)
      super(url)
      if fail_on_redirect
        fail WrongPageVisited, "Expected URL '#{url}', got '#{page.current_url}'" unless displayed?
      end
    end

    # Check to see if we eventually land on the right page
    #
    # @param wait_time_seconds [Integer] How long to wait for the correct page to load
    # @return [Boolean] true if the url loaded in the browser matches the url_matcher pattern
    # @raise [NoUrlMatcherForPage] if there's no url_matcher for this page
    def displayed?(wait_time_seconds = Capybara.default_wait_time)
      fail Gamera::NoUrlMatcherForPage if url_matcher.nil?
      start_time = Time.now
      loop do
        return true if page.current_url.chomp('/') =~ url_matcher
        break unless Time.now - start_time <= wait_time_seconds
        sleep(0.05)
      end
      false
    end

    # A method to wait for slow loading data on a page. Useful, for example,
    # when waiting on a page that shows the count of records loaded via a slow
    # web or import.
    #
    # @param retries [Integer] Number of times to reload the page before giving up
    # @param allowed_errors [Array] Array of errors that trigger a refresh, e.g.,  if an ExpectationNotMetError was raised during an acceptance test
    # @param block [Block] The block to execute after each refresh
    def with_refreshes(retries, allowed_errors = [RSpec::Expectations::ExpectationNotMetError], &block)
      retries_left ||= retries
      visit
      block.call(retries_left)
    rescue *allowed_errors => e
      retries_left -= 1
      retry if retries_left >= 0
      raise e
    end

    # This is a flag for tracking which page object classes don't cover all of
    # the elements and/or controls on the target web page.
    #
    # @return [Boolean] true unless everything's been captured in the page
    #   object class
    def sparse?
      false
    end

    # This is a utility method to clean up URLs formed by concatenation since we
    # sometimes ended up with "//" in the middle of URLs which broke the
    # url_matcher checks.
    #
    # @param elements [String] duck types
    # @return [String] of elements joined by single "/" characters.
    def path_join(*elements)
      "/#{elements.join('/')}".gsub(%r(//+}), '/')
    end
  end
end

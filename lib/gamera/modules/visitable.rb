module Gamera
  module Visitable
    # Methods to include on pages that are visitable, i.e. have a URL to visit and are then displayed.

    include Capybara::DSL

    # Open the page url in the browser specified in your Capybara configuration
    #
    # @param fail_on_redirect [Boolean] Whether to fail if the site redirects to a page that does not match the url_matcher regex
    # @raise [WrongPageVisited] if the site redirects to URL that doesn't match the url_matcher regex and fail_on_redirect is true
    def visit(fail_on_redirect: true)
      super(url)
      if fail_on_redirect
        fail Gamera::WrongPageVisited, "Expected URL '#{url}', got '#{page.current_url}'" unless displayed?
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

    # A reminder to implement a url method when using this module.
    def url
      fail NotImplementedError, 'To use the Visitable module, you must implement a url method'
    end
  end
end

# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'gamera'
  s.version     = '0.1.8'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Eric Dobbs', 'Glen Aultman-Bettridge', 'Jillian Rosile']
  s.email       = ['eric@dobbse.net', 'glenab@koansolutions.net', 'jillian.rosile@gmail.com']
  s.homepage    = 'http://gamera-team.github.io/gamera/'
  s.license     = 'MIT'
  s.summary     = 'PageObject pattern implementation based on Capybara'
  s.description = 'Provides a framework which lets you wrap any web page with a Ruby API.'

  s.required_ruby_version = '>= 2.1.0'

  s.files            = `git ls-files -- lib/*`.split("\n")

  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.require_path     = 'lib'

  s.cert_chain  = ['certs/glena-b.pem']
  s.signing_key = File.expand_path('~/.ssh/gem-private_key.pem') if $PROGRAM_NAME.end_with?('gem')

  s.add_dependency 'selenium-webdriver', '~> 3.4', '>= 3.4.4'
  s.add_dependency 'geckodriver-helper', '~> 0.0.3'
  s.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.13'
  s.add_dependency 'capybara', '~> 2.15', '>= 2.15.1'
  s.add_dependency 'capybara-screenshot', '~> 1.0', '>= 1.0.17'
  s.add_dependency 'sequel', '~> 4.49'

  # Using forks from the original project, because the PRs made by Jason Rush
  # to each of the gems are still pending. Once those go live, update these
  # lines to point at the original projects.
  s.add_dependency 'gamera-symbolmatrix', '~> 1.2', '>= 1.2.1'
  s.add_dependency 'gamera-sequel-fixture', '~> 2.0', '>= 2.0.4'

  s.add_development_dependency 'sinatra', '~> 2.0.0'
  s.add_development_dependency 'byebug', '~> 9.0', '>= 9.0.6'
  s.add_development_dependency 'rspec', '~> 3.6'
  s.add_development_dependency 'yard', '~> 0.9.9'
  s.add_development_dependency 'yardstick', '~> 0.9.9'
end

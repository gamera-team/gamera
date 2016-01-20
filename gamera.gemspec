# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path('lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'gamera'
  s.version     = '0.1.7'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Eric Dobbs', 'Glen Aultman-Bettridge', 'Jillian Rosile']
  s.email       = ['eric@dobbse.net', 'glenab@koansolutions.net', 'jillian.rosile@gmail.com']
  s.homepage    = 'http://gamera-team.github.io/gamera/'
  s.license     = 'MIT'
  s.summary     = 'PageObject pattern implementation based on Capybara'
  s.description = "Provides a framework which lets you wrap any web page with a Ruby API."

  s.required_ruby_version = '~> 2.1', '>= 2.1.0'

  s.files            = `git ls-files -- lib/*`.split("\n")

  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.require_path     = 'lib'

  s.cert_chain  = ['certs/glena-b.pem']
  s.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/

  s.add_dependency 'sinatra', '~> 1.4', '>= 1.4.5'
  s.add_dependency 'selenium-webdriver', '~> 2.45', '>= 2.45.0'
  s.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'
  s.add_dependency 'capybara', '~> 2.4', '>= 2.4.4'
  s.add_dependency 'capybara-screenshot', '~> 1.0', '>= 1.0.7'
  s.add_dependency 'sequel', '~> 4.20', '>= 4.20.0'

  # Using forks from the original project, because the PRs made by Jason Rush
  # to each of the gems are still pending. Once those go live, update these
  # lines to point at the original projects.
  s.add_dependency 'gamera-symbolmatrix', '~> 1.2', '>= 1.2.1'
  s.add_dependency 'gamera-sequel-fixture', '~> 2.0', '>= 2.0.4'

  s.add_development_dependency 'byebug', '~> 5.0', '>= 5.0.0'
  s.add_development_dependency 'rspec', '~> 3.1', '>= 3.1.0'
  s.add_development_dependency 'yard', '~> 0.8', '>= 0.8.7.2'
  s.add_development_dependency 'yardstick', '~> 0.9', '>= 0.9.9'
end

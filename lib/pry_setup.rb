$LOAD_PATH << '.'

require_relative '../spec/spec_helper'
require_relative '../spec/resources/simple_form/simple_form_page.rb'
require_relative '../spec/resources/simple_form/simple_form.rb'
require_relative '../spec/resources/simple_site/home_page.rb'
require_relative '../spec/resources/simple_site/redirect_page.rb'
require_relative '../spec/resources/simple_site/hit_counter_page.rb'
require_relative '../spec/resources/simple_site/simple_site.rb'

def simple_form_page
  @simple_form_page ||= SimpleFormPage.new
end

def home_page
  @home_page ||= HomePage.new
end

def hit_counter_page
  @hit_counter_page ||= HitCounterPage.new
end

def redirect_page
  @redirect_page ||= RedirectPage.new
end

def simple_site
  set_app SimpleSite.new
end

def simple_form
  set_app SimpleForm.new
end


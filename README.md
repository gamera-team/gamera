# gamera

[![Build Status](https://secure.travis-ci.org/gamera-team/gamera.png)](http://travis-ci.org/gamera-team/gamera)
[![Dependency Status](https://gemnasium.com/gamera-team/gamera.png)](https://gemnasium.com/gamera-team/gamera)

gamera lets you control and interact with web pages directly from your Ruby
code. Essentially, you can wrap any web page with a Ruby API.

## Table of Contents

- [Features](#features)
- [What is the Page Object Pattern?](#what-is-the-page-object-pattern)
- [Setup](#setup)
- [Basic usage](#using-gamera)
- [Using gamera with pry](#using-gamera-with-pry)
- [Contributing](#contributing)

## Features

- a lightweight way of implementing the PageObject pattern on top of Capybara
- a framework for abstracting web pages into Ruby classes
- rainbows, puppies and kittens for every user (not included)

## What is the Page Object Pattern?


The brilliant Martin Fowler describes the
[PageObject](http://martinfowler.com/bliki/PageObject.html) pattern in detail.
Here's is a list of the essential features of the pattern.

  - A PageObject creates an application-level API for a web page or section of a
      web page. For example, `create_user_account` instead of `fill in this
      field, click on this button`
  - A PageObject allows a software client to do or see anything that a human can.
  - A PageObject provides an easily programmable interface that hides details of
      the specific HTML controls and elements.
  - Changes to the underlying web page shouldn't alter the PageObject
      interface (as long as the web page still supports the same business
      processes)
  - The result of navigating from a PageObject (e.g. clicking on a link or
      submitting a form), should be another PageObject.

## Setup


gamera requires Ruby 1.9.3 or later. To install, add this line to your
`Gemfile` and run `bundle install`:

```ruby
gem 'gamera'
```

If you're not using Bundler, you can install with

```bash
gem install 'gamera'
```

## Using gamera


gamera has two primary classes:

  1. _Page_ is a base class which you can subclass to create specific page
  objects or you can create subclasses that capture additional common behavior
  (for example, flash messages in a Rails app, common header or footer menus
  and so forth) and extend those to create specific page objects.
  2. _Builder_ is a base class for capturing business process methods that
  require multiple page objects (for example, adding a new user to a new
  group, which might require creating a new user, creating a group and adding
  the user with each step occurring on different pages in the web app). In
  practice, `Builder` subclasses are also used to create or alter data in the
  system.

### Example: Use gamera's _Page_ class to create a user registration page object

Given a registration page that looks like

  ```html
  <html>
    <body>
      <h2>Register!</h2>
      <form action="#">
        <label for='first_name'>First Name</label> <input type='text' id='first_name'>
       <label for='last_name'>Last Name</label> <input type='text' id='last_name'>
       <label for='email'>Email</label> <input type='text' id='email'>
       <label for='password'>Email</label> <input type='text' id='password'>
       <input type='button' id='save_button' name='Save' value='Save'>
      </form>
      </detail>
    </body>
  </html>
  ```

create a corresponding page object class

  ```ruby
  require 'gamera'

  class RegistrationPage < Gamera::Page

    def initialize
      @url = 'http://example.com/registration'
      @url_matcher = %r{/registration}
    end

    def register_user(first_name:, last_name:, email_address:, password:)
      first_name_field.set(first_name)
      last_name_field.set(last_name)
      email_field.set(email)
      password_field.set(password)
      save
    end

    private

    def first_name_field
      find_field('First Name') # Capybara finder
    end

    def last_name_field
      find_field('Last Name') # Capybara finder
    end

    def email_address_field
      find_field('Email') # Capybara finder
    end

    def password_field
      find_field('Password') # Capybara finder
    end

    def save
      find_button('Save').click # Capybara finder
    end
  end

  ```

You could also simplify this by using
[Gamera::PageSection::Form](./doc/Gamera/PageSections/Form.html)

  ```ruby
  require 'gamera'

  class RegistrationPage < Gamera::Page

    def initialize
      @url = 'http://example.com/registration/new'
      @url_matcher = %r{/registration/new}

      form_fields = {
        first_name: 'First Name',
        last_name: 'Last Name',
        email: 'Email',
        password: 'Password'
      }
      @registration_form = Gamera::PageSections::Form.new(form_fields)
      def_delegators :registration_form, *registration_form.field_method_names
    end

    def register_user(first_name:, last_name:, email_address:, password:)
      first_name_field.set(first_name)
      last_name_field.set(last_name)
      email_field.set(email)
      password_field.set(password)
      save
    end

    private

    def save
      find_button('Save').click # Capybara finder
    end
  end

  ```

In either case, you can then call

  ```ruby
  rp = RegistrationPage.new
  rp.visit
  rp.register_user(first_name: 'Laurence',
                   last_name: 'Peltier',
                   email_address: 'lpeltier@example.com',
                   password: 'so_secret')
  ```

in your code to register a new user through your web app's registration page.

### Example: Extend gamera's _Page_ class to create a _RailsPage_ class

For a given web app, you may find that you want to capture other common elements
in your page objects, such as, for example, flash messages in a Rails app or a
navigational node that's common to the entire site. One approach to this is to
subclass `Page`, add the common elements and then use the new subclass as the
parent for the actual page object classes.

For a Rails app, a new `RailsPage` class might look something like

```ruby
   class RailsPage < Gamera::Page

     def flash_error
       flash_error_div.text
     end

     def flash_message
       flash_notice_div.text
     end

     def has_flash_message?(message)
       has_css?(flash_notice_css, text: message)
     end

     def has_flash_error?(error)
       has_css?(flash_error_css, text: error)
     end

     def has_no_flash_error?
       has_no_css?(flash_error_css)
     end

     def has_no_flash_message?
       has_no_css?(flash_notice_css)
     end

     def has_submission_problems?
       has_flash_error?('There were problems with your submission')
     end

     def fail_if_submission_problems
       fail(SubmissionProblemsError, flash_error.text) if has_submission_problems?
     end

     private

     def flash_error_css
       'div.flash.error'
     end

     def flash_notice_css
       'div.flash.notice'
     end

     def flash_error_div
       find(flash_error_css)
     end

     def flash_notice_div
       find(flash_notice_css)
     end
   end
```

This could then be used as the parent class for the _RegistrationPage_ in the
previous example, adding the ability to check the flash message when the user is
registered.

### Example: Creating a _Builder_ subclass to capture a multipage business
process

For this example, let's assume we're automating a task management site that
lets a manager assign task to members of her team and that we've already created
page objects for some of the pages: `NewTaskPage`,
`UserLoginPage`, `AssignTaskPage`. Then we might create a `AssignedTaskBuilder`
like so,

```ruby
require 'gamera'
require 'page_objects'

class AssignedTaskBuilder < Gamera::Builder.with_options(
:admin_email, :task_name, :task_due_date, :assignee_email
)
  def build
    user_login_page = UserLoginPage.new
    new_task_page = NewTaskPage.new
    assign_task_page = AssignTaskPage.new

    user_login_page.visit
    user_login_page.login_as(admin_email)
    new_task_page.visit
    new_task_page.create_task(task_name, task_due_date)
    assign_task_page.visit
    assign_task_page.assign(task_name: task_name, to: assignee)
  end

  # Give back a builder with default values set (say for easy test data setup)
  def assigned_task_builder
    AssignedTaskBuilder.new(
      admin_email: 'ann_admin@example.com',
      task_name: 'That thing you do'
      task_due_date: Time.now + 24.hours
      assignee: 'tessa_lation@example.com')
  end
end
```

Notice that an instance of the class won't actually do anything until the
`build` method is called. This lets us to defer the build until the data or
process neeeds to happen. The builder as data factory model allows us to reuse
the builder, change the defaults or create a new builder instance with
different defaults.

```ruby
require 'assigned_task_builder`
include AssignedTaskBuilder

assigned_task_builder # => builder with the default options
assigned_task_builder.build # => actually assign the default task
another_task_builder = assigned_task_builder.refine_with(task_name: 'That other
thing you do') # => a new builder with a different task name
another_task_builder.build # => assign the new task
```

## Using gamera with Pry


We've created some toy web apps in Sinatra and some simple page objects on top
of them to test gamera. You can play with some of the spec pages and apps in
pry, using the following

```bash
cd ~/workspace/talos/lib
pry -r ./pry_setup.rb
```

This will add convenience methods that can be used in pry

Start the single page SimpleForm web app from pry with `pry> simple_form`. Use
this:

```bash
pry> simple_form_page.visit
pry> simple_form_page.fill_in_form(:text => 'Entered Text', :selection => 'C')
pry> simple_form_page.submit
```

to fill in the form on the app and submit it.

To see page object examples which handles page redirection or return page
content, start the SimpleSite web app with

```bash
pry> simple_site
```

### Example: Page Redirection via Pry

```bash
pry> redirect_page.visit # => should redirect to home page
pry> redirect_page.displayed? # => false
pry> home_page.displayed? # => true
```

### Example: Content via Pry

```bash
pry> hit_counter_page.visit
pry> hit_counter_page.text =~ /You have visited this page 1 times/ # => match!
```

## Contributing

See this [great guide to contributing to Open Source projects from
GitHub](https://guides.github.com/activities/contributing-to-open-source/#contributing)

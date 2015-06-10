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

require_relative '../../lib/gamera/builder'

class User
  attr_reader :name, :bday

  def initialize(name:, bday:)
    @name = name
    @bday = bday
  end
end

describe Gamera::Builder do
  specify 'create_with initiates a Builder with parameters and a build method' do
    birthday = Time.now

    b = Gamera::Builder.create_with(
      name: 'Qatest',
      bday: birthday
    ) do
      User.new(name: name, bday: bday)
    end

    u = b.build
    expect(u.name).to eq('Qatest')
    expect(u.bday).to eq(birthday)
  end

  describe '.with_options return' do
    specify { expect(Gamera::Builder.with_options(:name)).to be_kind_of Class }

    describe 'created builder class' do
      subject(:builder_class) do
        Class.new(Gamera::Builder.with_options(:name, :bday)) do
          def build
            User.new(name: name, bday: bday)
          end
        end
      end

      specify { expect(subject).to define_method :with_name }
      specify { expect(subject).to define_method :name }
      specify { expect(subject).to define_method :with_bday }
      specify { expect(subject).to define_method :bday }

      context 'fully specified builder object' do
        subject(:builder) do
          builder_class.new
            .with_name('Qatest')
            .with_bday(birthday)
        end

        describe 'built object' do
          subject { builder.result }

          specify { expect(subject.name).to eq('Qatest') }
          specify { expect(subject.bday).to eq(birthday) }
        end
      end

      context 'partially specified builder object' do
        subject(:builder) do
          builder_class.new
            .with_name('Qatest')
        end

        describe 'built object' do
          subject { builder.result }

          specify { expect(subject.name).to eq 'Qatest' }
          specify { expect(subject.bday).to be_nil }
        end
      end

      context 'with simple default value' do
        before do
          birthday_ = birthday
          builder_class.class_exec do
            default_for :name, 'Jane'
            default_for :bday, birthday_ - 1
          end
        end

        subject(:builder) do
          builder_class.new
            .with_name('Qatest')
        end

        describe 'built object' do
          subject { builder.result }

          specify 'explicitly provided values supersede defaults' do
            expect(subject.name).to eq 'Qatest'
          end
          specify { expect(subject.bday).to eq birthday - 1 }
        end
      end

      context 'with default value generator' do
        before do
          birthday_ = birthday
          builder_class.class_exec do
            default_for :name do
              'Bob'
            end
          end
        end

        subject(:builder) { builder_class.new }

        describe 'built object' do
          subject { builder.result }

          specify { expect(subject.name).to eq 'Bob' }
        end
      end
    end

    # background
    let(:birthday) { Time.now }
  end

  specify 'with_options method allows creation of helper methods' do
    birthday = Time.now

    class AlternateUserBuilder < Gamera::Builder.with_options(:name, :bday)
      def build
        User.new(name: name, bday: bday)
      end

      def born_on(date)
        refine_with(bday: date)
      end
    end

    ub = AlternateUserBuilder.new
         .with_name('Qatest')
         .born_on(birthday)
    u = ub.build
    expect(u.name).to eq('Qatest')
    expect(u.bday).to eq(birthday)
  end

  matcher :define_method do |expected|
    match do |actual|
      actual.instance_methods.include? expected
    end
  end
end

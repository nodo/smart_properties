require 'spec_helper'

describe SmartProperties do

  context "when extending an other class" do

    subject do
      Class.new.tap do |c|
        c.send(:include, described_class)
      end
    end

    it "should add a .property method" do
      subject.should respond_to(:property)
    end

    context "and defining a property with invalid configuration options" do

      it "should raise an error reporting one invalid option when one invalid option was given" do
        expect {
          subject.tap do |c|
            c.instance_eval do
              property :title, :invalid_option => 'boom'
            end
          end
        }.to raise_error(ArgumentError, "SmartProperties do not support the following configuration options: invalid_option.")
      end

      it "should raise an error reporting three invalid options when three invalid options were given" do
        expect {
          subject.tap do |c|
            c.instance_eval do
              property :title, :invalid_option_1 => 'boom', :invalid_option_2 => 'boom', :invalid_option_3 => 'boom'
            end
          end
        }.to raise_error(ArgumentError, "SmartProperties do not support the following configuration options: invalid_option_1, invalid_option_2, invalid_option_3.")
      end

    end

  end

  context "when used to build a class that has a property called :title" do

    subject do
      title = Object.new.tap do |o|
        def o.to_title; 'chunky'; end
      end

      klass = Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          def name; "TestDummy"; end

          property :title, :accepts => String,
                                 :converts => :to_title,
                                 :required => true,
                                 :default => title
        end
      end

      klass
    end

    it { should have_smart_property(:title) }

    context "instances of this class" do

      klass = subject.call

      subject do
        klass.new
      end

      it { should respond_to(:title) }
      it { should respond_to(:title=) }

      it "should have 'chucky' as default value for title" do
        subject.title.should be == 'chunky'
      end

      it "should convert all values that are assigned to title into strings" do
        subject.title = double(:to_title => 'bacon')
        subject.title.should be == 'bacon'
      end

      it "should not allow to set nil as title" do
        expect { subject.title = nil }.to raise_error(ArgumentError, "TestDummy requires the property title to be set")
      end

      it "should not allow to set objects as title that do not respond to #to_title" do
        expect { subject.title = Object.new }.to raise_error(ArgumentError, "Object does not respond to #to_title")
      end

      it "should not influence other instances that have been initialized with different attributes" do
        other = klass.new :title => double(:to_title => 'Lorem ipsum')

        subject.title.should be == 'chunky'
        other.title.should   be == 'Lorem ipsum'
      end

      context "when initialized with a block" do

        subject do
          klass.new do |c|
            c.title = double(:to_title => 'bacon')
          end
        end

        it "should have the title specified in the block" do
          subject.title.should be == 'bacon'
        end

      end

    end

    context "when subclassed" do

      superklass = subject.call

      subject do
        Class.new(superklass)
      end

      it { should have_smart_property(:title) }

      context "instances of this subclass" do

        klass = subject.call

        subject do
          klass.new
        end

        it { should respond_to(:title) }
        it { should respond_to(:title=) }

      end

      context "instances of this subclass that have been intialized from a set of attributes" do

        klass = subject.call

        subject do
          klass.new :title => stub(:to_title => 'Message')
        end

        it "should have the correct title" do
          subject.title.should be == 'Message'
        end

      end

    end

    context "when subclassed and extended with a property called text" do

      superklass = subject.call

      subject do
        Class.new(superklass).tap do |c|
          c.instance_eval do
            property :text
          end
        end
      end

      it { should have_smart_property(:title) }
      it { should have_smart_property(:text) }

      context "instances of this subclass" do

        klass = subject.call

        subject do
          klass.new
        end

        it { should respond_to(:title) }
        it { should respond_to(:title=) }
        it { should respond_to(:text) }
        it { should respond_to(:text=) }

      end

      context "instances of the super class" do

        subject do
          superklass.new
        end

        it { should_not respond_to(:text) }
        it { should_not respond_to(:text=) }

      end

      context "instances of this subclass" do

        klass = subject.call

        context "when initialized with a set of attributes" do

          subject do
            klass.new :title => stub(:to_title => 'Message'), :text => "Hello"
          end

          it "should have the correct title" do
            subject.title.should be == 'Message'
          end

          it "should have the correct text" do
            subject.text.should be == 'Hello'
          end

        end

        context "when initialized with a block" do

          subject do
            klass.new do |c|
              c.title = stub(:to_title => 'Message')
              c.text = "Hello"
            end
          end

          it "should have the title specified in the block" do
            subject.title.should be == 'Message'
          end

          it "should have the text specified in the block" do
            subject.text.should be == 'Hello'
          end

        end

      end

    end

    context "when extended with a :type property at runtime" do

      klass = subject.call

      subject do
        klass.tap do |c|
          c.instance_eval do
            property :type, :converts => :to_sym
          end
        end
      end

      it { should have_smart_property(:title) }
      it { should have_smart_property(:type) }

      context "instances of this class" do

        klass = subject.call

        subject do
          klass.new :title => double(:to_title => 'Lorem ipsum')
        end

        it { should respond_to(:type)  }
        it { should respond_to(:type=) }

      end

      context "when subclassing this class" do

        superklass = subject.call

        subject do
          Class.new(superklass)
        end

        context "instances of this class" do

          klass = subject.call

          subject do
            klass.new :title => double(:to_title => 'Lorem ipsum')
          end

          it { should respond_to :title }
          it { should respond_to :title= }

          it { should respond_to :type }
          it { should respond_to :type= }

        end

      end

    end

  end

  context "when used to build a class that has a property called :title which a lambda statement for conversion" do

    subject do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          property :title, :converts => lambda { |t| "<title>#{t.to_s}</title>"}
        end
      end
    end

    context "instances of this class" do

      klass = subject.call

      subject do
        klass.new
      end

      it "should convert the property title as specified the lambda statement" do
        subject.title = "Lorem ipsum"
        subject.title.should be == "<title>Lorem ipsum</title>"
      end

    end

  end

  context "when used to build a class that has a property called :visible which uses an array of valid values for acceptance checking" do

    subject do
      Class.new.tap do |c|
        def c.name; "TestDummy"; end

        c.send(:include, described_class)

        c.instance_eval do
          property :visible, :accepts => [true, false]
        end
      end
    end

    context "instances of this class" do

      klass = subject.call

      subject do
        klass.new
      end

      it "should allow to set true as value for visible" do
        expect { subject.visible = true }.to_not raise_error
      end

      it "should allow to set false as value for visible" do
        expect { subject.visible = false }.to_not raise_error
      end

      it "should not allow to set :maybe as value for visible" do
        expect { subject.visible = :maybe }.to raise_error(ArgumentError, "TestDummy does not accept :maybe as value for the property visible")
      end

    end

  end

  context 'when used to build a class that has a property called :license_plate which uses a lambda statement for accpetance checking' do

    subject do
      Class.new.tap do |c|
        def c.name; 'TestDummy'; end

        c.send(:include, described_class)

        c.instance_eval do
          property :license_plate, :accepts => lambda { |v| /\w{1,2} \w{1,2} \d{1,4}/.match(v) }
        end
      end
    end

    context 'instances of this class' do

      klass = subject.call

      subject do
        klass.new
      end

      it 'should not a accept "invalid" as value for license_plate' do
        expect { subject.license_plate = "invalid" }.to raise_error(ArgumentError, 'TestDummy does not accept "invalid" as value for the property license_plate')
      end

      it 'should accept "NE RD 1337" as license plate' do
        expect { subject.license_plate = "NE RD 1337" }.to_not raise_error
      end

    end

  end

  context 'when used to build a class that has a property called :text whose getter is overriden' do

    subject do
      Class.new.tap do |c|
        c.send(:include, described_class)

        c.instance_eval do
          property :text, :default => 'Hello'
        end

        c.class_eval do
          def text
            "<em>#{super}</em>"
          end
        end
      end
    end

    context "instances of this class" do

      klass = subject.call

      subject do
        klass.new
      end

      it "should return the accepted value for the property called :text" do
        subject.text.should be == '<em>Hello</em>'
      end

    end

  end

  context 'when used to build a class that has a property called :id whose default value is a lambda statement' do

    subject do
      counter = Class.new.tap do |c|

        c.class_eval do
          def next
            @counter ||= 0
            @counter += 1
          end
        end

      end.new

      Class.new.tap do |c|
        c.send(:include, described_class)

        c.instance_eval do
          property :id, :default => lambda { counter.next }
        end
      end
    end

    context "instances of this class" do

      klass = subject.call

      it "should have auto-incrementing ids" do
        first_instance = klass.new
        second_instance = klass.new

        (second_instance.id - first_instance.id).should be == 1
      end

    end

  end

  context 'when used to build a class that is then subclassed and later extended at runtime' do

    let!(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :title)
      end
    end

    let!(:subklass) do
      Class.new(klass).tap do |c|
        c.send(:property, :body)
      end
    end

    before do
      klass.tap do |c|
        c.send(:property, :priority)
      end
    end

    context "the class" do

      subject { klass }

      it { should have_smart_property(:title) }
      it { should have_smart_property(:priority) }

    end

    context 'the subclass' do

      subject { subklass }

      it { should have_smart_property(:title) }
      it { should have_smart_property(:body) }
      it { should have_smart_property(:priority) }

      it "should be initializable using a block" do
        configuration_instructions = lambda do |s|
          s.title = "Lorem Ipsum"
          s.priority = :low
          s.body = "Lorem ipsum dolor sit amet."
        end

        expect { subject.new(&configuration_instructions) }.to_not raise_error
      end

      it "should be initializable using a hash of attributes" do
        attributes = {
          :title => "Lorem Ipsum",
          :priority => :low,
          :body => "Lorem ipsum dolor sit amet."
        }

        expect { subject.new(attributes) }.to_not raise_error
      end

    end

  end

  context "when building a class that has a property which is not required and has a default" do

    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :title, :default => 'Lorem Ipsum')
      end
    end

    context 'instances of that class' do

      context 'when created with a set of attributes that explicitly contains nil for the title' do

        subject(:instance) { klass.new :title => nil }

        it "should have no title" do
          instance.title.should be_nil
        end

      end

      context 'when created without any arguments' do

        subject(:instance) { klass.new }

        it "should have the default title" do
          instance.title.should be == 'Lorem Ipsum'
        end

      end

      context 'when created with an empty block' do

        subject(:instance) { klass.new {} }

        it "should have the default title" do
          instance.title.should be == 'Lorem Ipsum'
        end

      end

    end

  end

  context "when building a class that has a property which is required and has no default" do

    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :title, :required => true)

        def c.name; "Dummy"; end
      end
    end

    context 'instances of that class' do

      context 'when created with a set of attributes that explicitly contains nil for the title' do

        subject(:instance) { klass.new :title => 'Lorem Ipsum' }

        it "should have no title" do
          instance.title.should be == 'Lorem Ipsum'
        end

      end

      context 'when created with an block specifying that property' do

        subject(:instance) { klass.new { |i| i.title = 'Lorem Ipsum' } }

        it "should have the default title" do
          instance.title.should be == 'Lorem Ipsum'
        end

      end

      context "when created with no arguments" do

        it "should raise an error stating that required properties are missing" do
          expect { subject.new }.to raise_error(ArgumentError, "Dummy requires the following properties to be set: title")
        end

      end

    end

  end

  context "when building a class that has a property which is required and has false as default" do

    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :flag, :required => true, :default => false)

        def c.name; "Dummy"; end
      end
    end

    context 'instances of that class' do

      context 'when created with a set of attributes that explicitly contains nil for the title' do

        subject(:instance) { klass.new :flag => true }

        it "should have no title" do
          instance.flag.should be_true
        end

      end

      context 'when created with an block specifying that property' do

        subject(:instance) { klass.new { |i| i.flag = true } }

        it "should have the default title" do
          instance.flag.should be_true
        end

      end

      context "when created with no arguments" do

        subject(:instance) { klass.new }

        it "should have false as default flag" do
          instance.flag.should be_false
        end

      end

    end

  end

end

module RSpec
  class ExpectationNotMetError < StandardError; end

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  class Configuration
    attr_reader :before_suite_hooks, :around_each_hooks

    def initialize
      @before_suite_hooks = []
      @around_each_hooks = []
      @current_example_group = nil
    end

    def before(scope = :each, &block)
      if scope == :suite
        @before_suite_hooks << block
      else
        current_example_group.before_each_hooks << block
      end
    end

    def around(scope = :each, &block)
      return unless scope == :each
      @around_each_hooks << block
    end

    def current_example_group=(group)
      @current_example_group = group
    end

    def current_example_group
      @current_example_group
    end
  end

  def self.describe(description, &block)
    group = ExampleGroup.new(description)
    configuration.current_example_group = group
    group.instance_eval(&block) if block
    Runner.register(group)
    group
  end

  def self.expect(actual = nil, &block)
    actual = block if block_given? && actual.nil?
    ExpectationTarget.new(actual)
  end

  class ExpectationTarget
    def initialize(actual)
      @actual = actual
    end

    def to(matcher)
      raise ExpectationNotMetError, matcher.failure_message unless matcher.matches?(@actual)
    end

    def not_to(matcher)
      raise ExpectationNotMetError, matcher.negative_failure_message if matcher.matches?(@actual)
    end
  end

  module Matchers
    class Eq
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        @actual = actual
        actual == @expected
      end

      def failure_message
        "expected #{@expected.inspect} but got #{@actual.inspect}"
      end

      def negative_failure_message
        "expected value not to equal #{@expected.inspect}"
      end
    end

    class BeNil
      def matches?(actual)
        @actual = actual
        actual.nil?
      end

      def failure_message
        "expected nil but got #{@actual.inspect}"
      end

      def negative_failure_message
        "expected value not to be nil"
      end
    end

    class BeTruthy
      def matches?(actual)
        !!actual
      end

      def failure_message
        "expected value to be truthy"
      end

      def negative_failure_message
        "expected value to be falsy"
      end
    end

    class BeGreaterThan
      def initialize(expected)
        @expected = expected
      end

      def matches?(actual)
        @actual = actual
        actual > @expected
      end

      def failure_message
        "expected #{@actual.inspect} to be greater than #{@expected.inspect}"
      end

      def negative_failure_message
        "expected #{@actual.inspect} not to be greater than #{@expected.inspect}"
      end
    end

    class Change
      def initialize(object_proc, _message = nil)
        @object_proc = object_proc
      end

      def by(expected)
        @expected = expected
        self
      end

      def matches?(trigger)
        before = @object_proc.call
        trigger.call
        after = @object_proc.call
        @actual_change = after - before
        @actual_change == @expected
      end

      def failure_message
        "expected change of #{@expected}, got #{@actual_change}"
      end

      def negative_failure_message
        "expected change not to be #{@expected}"
      end
    end
  end

  def self.eq(expected)
    Matchers::Eq.new(expected)
  end

  def self.be_nil
    Matchers::BeNil.new
  end

  def self.be_truthy
    Matchers::BeTruthy.new
  end

  def self.be_greater_than(expected)
    Matchers::BeGreaterThan.new(expected)
  end

  def self.change(object_proc, message = nil)
    Matchers::Change.new(object_proc, message)
  end

  class ExampleGroup
    attr_reader :description, :examples, :before_each_hooks

    def initialize(description)
      @description = description
      @examples = []
      @before_each_hooks = []
    end

    def it(desc, &block)
      @examples << Example.new(desc, block, self)
    end

    def before(scope = :each, &block)
      return unless scope == :each
      @before_each_hooks << block
    end

    def describe(desc, &block)
      subgroup = ExampleGroup.new(desc)
      subgroup.instance_eval(&block)
      @examples << subgroup
    end
  end

  class Example
    attr_reader :description

    def initialize(description, block, group)
      @description = description
      @block = block
      @group = group
    end

    def run
      @group.before_each_hooks.each { |hook| hook.call }
      if RSpec.configuration.around_each_hooks.empty?
        @block.call
      else
        chain = RSpec.configuration.around_each_hooks.reduce(@block) do |acc, hook|
          proc { hook.call(acc) }
        end
        chain.call
      end
    end
  end

  module Runner
    module_function

    def register(group)
      groups << group
    end

    def groups
      @groups ||= []
    end

    def run
      failures = []
      RSpec.configuration.before_suite_hooks.each { |hook| hook.call }

      groups.each do |group|
        group.examples.each do |example|
          next if example.is_a?(ExampleGroup)
          begin
            example.run
            puts "✅ #{group.description} #{example.description}"
          rescue ExpectationNotMetError => e
            failures << "#{group.description} #{example.description}: #{e.message}"
            puts "❌ #{group.description} #{example.description}: #{e.message}"
          rescue StandardError => e
            failures << "#{group.description} #{example.description}: #{e.class} #{e.message}"
            puts "❌ #{group.description} #{example.description}: #{e.class} #{e.message}"
          end
        end
      end

      if failures.empty?
        puts "\nAll examples passed"
        0
      else
        puts "\nFailures:\n- " + failures.join("\n- ")
        1
      end
    end
  end
end

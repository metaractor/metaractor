require 'metaractor'
require 'forwardable'

module Metaractor
  module Spec
    module Helpers
      def context_creator(error_message: nil, error_messages: [], errors: [], valid: nil, invalid: nil, success: nil, failure: nil, **attributes)
        if error_message.present?
          error_messages << error_message
        end

        result = Interactor::Context.build(attributes)
        result.add_errors(messages: error_messages)
        result.add_errors(errors: errors)

        if (valid != nil && !valid) || (invalid != nil && invalid)
          result.invalidate!
        end

        if !result.errors.empty? || (success != nil && !success) || (failure != nil && failure)
          result.fail! rescue Interactor::Failure
        end

        result
      end
    end

    module Matchers
      def include_errors(*expected)
        Metaractor::Spec::Matchers::IncludeErrors.new(*expected)
      end

      class IncludeErrors
        extend Forwardable

        def initialize(*expected)
          @expected = expected
          @include = RSpec::Matchers::BuiltIn::Include.new(*@expected)
        end

        def matches?(actual)
          @actual = actual
          @include.matches?(full_messages)
        end

        def does_not_match?(actual)
          @actual = actual
          @include.does_not_match?(full_messages)
        end

        def at_path(*path)
          @path = path
          self
        end

        def_delegators :@include, :description, :failure_message, :failure_message_when_negated, :diffable?, :actual, :expected

        private

        def full_messages
          if @path
            @actual.errors.full_messages_for(*@path)
          else
            @actual.errors.full_messages
          end
        end
      end
    end

  end
end

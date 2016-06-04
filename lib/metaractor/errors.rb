module Metaractor
  class Error < StandardError; end
  class InvalidError < Error; end

  module Errors
    def self.included(base)
      base.class_eval do
        before :initialize_errors_array
      end
    end

    def initialize_errors_array
      context.errors ||= []
    end

    def fail_with_error!(message:)
      add_error(message: message)
      context.fail!
    end

    def fail_with_errors!(messages:)
      add_errors(messages: messages)
      context.fail!
    end

    def add_error(message:)
      add_errors(messages: Array(message))
    end

    def add_errors(messages:)
      context.errors ||= []
      context.errors += messages
    end

    def error_messages
      context.errors.join("\n")
    end
  end
end

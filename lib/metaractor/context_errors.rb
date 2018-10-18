module Metaractor
  module ContextErrors
    def errors
      if super.nil?
        self.errors = []
      end

      super
    end

    def fail_with_error!(message:)
      add_error(message: message)
      fail!
    end

    def fail_with_errors!(messages:)
      add_errors(messages: messages)
      fail!
    end

    def add_error(message:)
      add_errors(messages: Array(message))
    end

    def add_errors(messages:)
      self.errors += messages
    end

    def error_messages
      errors.join("\n")
    end
  end
end

Interactor::Context.send(:include, Metaractor::ContextErrors)

module Metaractor
  module ContextErrors
    def errors
      if super.nil?
        self.errors = Metaractor::Errors.new
      end

      super
    end

    def fail_with_error!(message: nil, errors: nil)
      add_error(message: message, errors: errors)
      fail!
    end

    def fail_with_errors!(messages: [], errors: {})
      add_errors(messages: messages, errors: errors)
      fail!
    end

    def add_error(message: nil, errors: nil)
      if message.nil?
        add_errors(errors: errors)
      else
        add_errors(messages: Array(message))
      end
    end

    def add_errors(messages: [], errors: {})
      if !messages.empty?
        self.errors.add(errors: { base: messages })
      else
        self.errors.add(errors: errors)
      end
    end

    def error_messages
      errors.full_messages
    end
  end
end

Interactor::Context.send(:include, Metaractor::ContextErrors)

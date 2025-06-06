module Metaractor
  module ContextErrors
    def errors
      if super.nil?
        self.errors = Metaractor::Errors.new
      end

      super
    end

    def fail_with_error!(message: nil, errors: nil, **args)
      add_error(message: message, errors: errors, **args)
      fail!
    end

    def fail_with_errors!(messages: [], errors: {}, **args)
      add_errors(messages: messages, errors: errors, **args)
      fail!
    end

    def add_error(message: nil, errors: nil, **args)
      if message.nil?
        add_errors(errors: errors, **args)
      else
        add_errors(messages: Array(message), **args)
      end
    end

    def add_errors(messages: [], errors: {}, **args)
      retry! if args.delete(:retry)

      if !messages.empty?
        self.errors.add(errors: {base: messages}, **args)
      else
        self.errors.add(errors: errors, **args)
      end
    end

    def error_messages
      errors.full_messages
    end

    def fail_from_context(context:)
      return if context.equal?(self)

      invalidate! if context.invalid?
      add_errors(errors: context.errors.to_h)
      @failure = true
    end
  end
end

Interactor::Context.send(:include, Metaractor::ContextErrors)

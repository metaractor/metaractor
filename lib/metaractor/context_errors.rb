module Metaractor
  module ContextErrors
    def errors
      if super.nil?
        self.errors = []
      end

      super
    end

    def fail_with_error!(message: nil, **args)
      add_error(message: message, **args)
      fail!
    end

    def fail_with_errors!(messages: [], errors: [])
      add_errors(messages: messages, errors: errors)
      fail!
    end

    def add_error(message: nil, **args)
      if message.nil?
        add_errors(errors: [**args])
      else
        add_errors(messages: Array(message))
      end
    end

    def add_errors(messages: [], errors: [])
      self.errors += messages
      self.errors += errors
    end

    def error_messages
      errors.map do |error|
        if error.respond_to?(:has_key?) && error.has_key?(:title)
          if error[:source] != nil
            "#{error[:source]}: #{error[:title]}"
          else
            error[:title].to_s
          end
        else
          error.to_s
        end
      end.join("\n")
    end
  end
end

Interactor::Context.send(:include, Metaractor::ContextErrors)

module Metaractor
  class Error < StandardError; end
  class InvalidError < Error; end

  module HandleErrors
    def fail_with_error!(**args)
      context.fail_with_error!(object: self, **args)
    end

    def fail_with_errors!(**args)
      context.fail_with_errors!(object: self, **args)
    end

    def add_error(**args)
      context.add_error(object: self, **args)
    end

    def add_errors(**args)
      context.add_errors(object: self, **args)
    end

    def error_messages
      context.error_messages
    end
  end
end

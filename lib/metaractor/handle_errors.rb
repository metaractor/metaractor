module Metaractor
  class Error < StandardError; end
  class InvalidError < Error; end

  module HandleErrors
    def fail_with_error!(*args)
      context.fail_with_error!(*args)
    end

    def fail_with_errors!(*args)
      context.fail_with_errors!(*args)
    end

    def add_error(*args)
      context.add_error(*args)
    end

    def add_errors(*args)
      context.add_errors(*args)
    end

    def error_messages
      context.error_messages
    end
  end
end

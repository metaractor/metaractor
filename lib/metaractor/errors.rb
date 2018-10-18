require 'forwardable'

module Metaractor
  class Error < StandardError; end
  class InvalidError < Error; end

  module Errors
    def self.included(base)
      base.class_eval do
        extend Forwardable
        def_delegators :context,
          :fail_with_error!,
          :fail_with_errors!,
          :add_error,
          :add_errors,
          :error_messages
      end
    end
  end
end

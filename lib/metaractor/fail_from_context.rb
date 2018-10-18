module Metaractor
  module FailFromContext
    def fail_from_context(context:)
      return if context.equal?(self)

      invalidate! if context.invalid?
      add_errors(messages: context.errors)
      @failure = true
    end
  end
end

Interactor::Context.send(:include, Metaractor::FailFromContext)

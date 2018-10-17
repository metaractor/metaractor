module Metaractor
  module FailFromContext
    def fail_from_context(context:)
      invalidate! if context.invalid?
      add_errors(messsages: context.errors)
      @failure = true
    end
  end
end

Interactor::Context.send(:include, Metaractor::FailFromContext)

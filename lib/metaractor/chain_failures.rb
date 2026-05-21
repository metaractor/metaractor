module Metaractor
  module ChainFailures
    def self.included(base)
      base.class_eval do
        around :chain_nested_failures
      end
    end

    def chain_nested_failures(interactor)
      interactor.call
    rescue Interactor::Failure => e
      context.fail_from_context(context: e.context)
      raise
    end

    def run
      run!
    rescue Interactor::Failure
      # Intentionally rescue all Failures as we're
      # handling child errors by failing the parents
      # instead of allowing the child to raise
      # all of the way up.
      # Needed since Interactor v3.2.0.
    end
  end
end

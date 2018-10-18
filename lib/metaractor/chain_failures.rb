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
  end
end

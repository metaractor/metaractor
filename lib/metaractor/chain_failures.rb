module Metaractor
  module ChainFailures
    def call
      super
    rescue Interactor::Failure => e
      context.fail_from_context(context: e.context)
      raise
    end
  end
end

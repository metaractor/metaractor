module Metaractor
  module ChainFailures
    def call
      super
    rescue Interactor::Failure => e
      context.invalidate! if e.context.invalid?
      context.fail_with_errors!(messsages: e.context.errors)
      raise
    end
  end
end

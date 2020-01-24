module Metaractor
  module ContextHasKey
    def has_key?(key)
      @table.has_key?(key.to_sym)
    end
  end
end

Interactor::Context.send(:include, Metaractor::ContextHasKey)

module Metaractor
  module ContextMethods
    def valid?
      !invalid?
    end

    def invalid?
      @invalid || false
    end

    def invalidate!
      @invalid = true
    end

    def has_key?(key)
      @table.has_key?(key.to_sym)
    end

    def retry?
      @retry || false
    end

    def retry!
      @retry = true
    end
  end
end

Interactor::Context.send(:include, Metaractor::ContextMethods)

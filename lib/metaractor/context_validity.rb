module Metaractor
  module ContextValidity
    def valid?
      !invalid?
    end

    def invalid?
      @invalid || false
    end

    def invalidate!
      @invalid = true
    end
  end
end

Interactor::Context.send(:include, Metaractor::ContextValidity)

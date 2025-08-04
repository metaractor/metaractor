module Metaractor
  module Delegation
    def respond_to_missing?(name, include_private = false)
      return false if name == :marshal_dump || name == :_dump
      context.has_key?(name) || super
    end

    def method_missing(name, ...)
      if context.has_key?(name)
        context.public_send(name, ...)
      else
        super
      end
    end
  end
end

module Metaractor
  module Parameters
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include Metaractor::Errors

        class << self
          attr_writer :_required_parameters
          attr_writer :_optional_parameters
          attr_writer :_allow_blank
        end

        before :remove_blank_values
        before :validate_required_parameters
      end
    end

    module ClassMethods
      def _required_parameters
        @_required_parameters ||= []
      end

      def required(*params)
        self._required_parameters += params
      end
      alias_method :required_parameters, :required

      def _optional_parameters
        @_optional_parameters ||= []
      end

      def optional(*params)
        self._optional_parameters += params
      end

      def _allow_blank
        @_allow_blank ||= []
      end

      def allow_blank(*params)
        self._allow_blank += params
      end

      def validate_parameters(*hooks, &block)
        hooks << block if block
        hooks.each {|hook| validate_hooks.push(hook) }
      end

      def validate_hooks
        @validate_hooks ||= []
      end
    end

    def remove_blank_values
      to_delete = []
      context.each_pair do |k,v|
        next if self.class._allow_blank.include?(k)

        # The following regex is borrowed from Rails' String#blank?
        to_delete << k if (v.is_a?(String) && /\A[[:space:]]*\z/ === v) || v.nil?
      end
      to_delete.each do |k|
        context.delete_field k
      end
    end

    def validate_required_parameters
      context.errors ||= []

      self.class._required_parameters.each do |param|
        require_parameter param
      end

      run_validate_hooks

      context.fail! unless context.errors.empty?
    end

    def require_parameter(param, message: nil)
      message_override = message
      valid, message = parameter_valid? param

      if !valid
        if message_override != nil
          add_parameter_error(param: param, message: message_override)
        else
          add_parameter_error(message: "Required parameters: #{message}")
        end
      end
    end

    def parameter_valid?(param)
      # implements a depth-first post-order traversal
      if param.respond_to?(:to_h)
        param = param.to_h
        raise "invalid required parameter #{param.inspect}" unless param.keys.size == 1
        raise "invalid required parameter #{param.inspect}" unless param.values.first.respond_to?(:to_a)

        operator = param.keys.first
        params = param.values.first.to_a

        valids = []
        messages = []
        params.each do |key|
          valid, message = parameter_valid?(key)
          valids << valid
          messages << message
        end

        case operator
        when :or
          return valids.any?, "(#{messages.join(' or ')})"
        when :xor
          return valids.one?, "(#{messages.join(' xor ')})"
        when :and
          return valids.all?, "(#{messages.join(' and ')})"
        else
          raise "invalid required parameter #{param.inspect}"
        end
      else
        return context[param] != nil, param.to_s
      end
    end

    def require_parameter!(param, message: nil)
      require_parameter param, message: message
      context.fail! unless context.errors.empty?
    end

    def run_validate_hooks
      run_hooks(self.class.validate_hooks)
    end

    def add_parameter_error(param: nil, message:)
      add_error(
        message: "#{param} #{message}".lstrip
      )

      context.invalidate!
    end
  end
end

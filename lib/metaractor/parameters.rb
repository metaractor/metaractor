# Special thanks to the `hashie` and `active_attr` gems for code and inspiration.

module Metaractor
  module Parameters
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include Metaractor::HandleErrors

        class << self
          attr_writer :requirement_trees
        end

        before :remove_blank_values
        before :apply_defaults
        before :validate_required_parameters
      end
    end

    class Parameter
      include Comparable

      attr_reader :name

      def initialize(name, **options)
        @name = name.to_sym
        @options = options
      end

      def <=>(other)
        return nil unless other.instance_of? self.class
        return nil if name == other.name && options != other.options
        self.name.to_s <=> other.name.to_s
      end

      def [](key)
        @options[key]
      end

      def dig(name, *names)
        @options.dig(name, *names)
      end

      def merge!(**options)
        @options.merge!(**options)
      end

      def to_s
        name.to_s
      end

      def to_sym
        name
      end

      protected
      attr_reader :options
    end

    module ClassMethods
      def parameter(name, **options)
        if param = self.parameter_hash[name.to_sym]
          param.merge!(**options)
        else
          Parameter.new(name, **options).tap do |parameter|
            self.parameter_hash[parameter.name] = parameter
          end
        end
      end

      def parameters(*names, **options)
        names.each do |name|
          parameter(name, **options)
        end
      end

      def parameter_hash
        @parameters ||= {}
      end

      def requirement_trees
        @requirement_trees ||= []
      end

      def required(*params, **options)
        if params.empty?
          tree = options
          self.requirement_trees << tree
          parameters(*parameters_in_tree(tree), required: tree)
        else
          parameters(*params, required: true, **options)
        end
      end

      def optional(*params, **options)
        parameters(*params, **options)
      end

      def validate_parameters(*hooks, &block)
        hooks << block if block
        hooks.each {|hook| validate_hooks.push(hook) }
      end

      def validate_hooks
        @validate_hooks ||= []
      end

      def parameters_in_tree(tree)
        if tree.respond_to?(:to_h)
          tree.to_h.values.first.to_a.flat_map {|t| parameters_in_tree(t)}
        else
          [tree]
        end
      end
    end

    def parameters
      self.class.parameter_hash
    end

    def requirement_trees
      self.class.requirement_trees
    end

    def requirement_trees=(trees)
      self.class.requirement_trees=(trees)
    end

    def remove_blank_values
      to_delete = []
      context.each_pair do |name, value|
        next if parameters.dig(name, :allow_blank)

        # The following regex is borrowed from Rails' String#blank?
        to_delete << name if (value.is_a?(String) && /\A[[:space:]]*\z/ === value) || value.nil?
      end

      to_delete.each do |name|
        context.delete_field name
      end
    end

    def apply_defaults
      parameters.each do |name, parameter|
        next unless parameter[:default]

        unless context.has_key?(name)
          context[name] = _parameter_default(name)
        end
      end
    end

    def _parameter_default(name)
      default = self.parameters[name][:default]

      case
      when default.respond_to?(:call) then instance_exec(&default)
      when default.respond_to?(:dup) then default.dup
      else default
      end
    end

    def validate_required_parameters
      context.errors ||= []

      parameters.each do |name, parameter|
        next if !parameter[:required] ||
          parameter[:required].is_a?(Hash)

        require_parameter name
      end

      requirement_trees.each do |tree|
        require_parameter tree
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

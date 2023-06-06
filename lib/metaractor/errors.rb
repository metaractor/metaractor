require "sycamore"
require "forwardable"
module Metaractor
  class Errors
    extend Forwardable

    class Error
      attr_reader :value, :object

      def initialize(value:, object: nil)
        @value = value
        @object = object
      end

      def generate_message(path_elements:)
        if @value.is_a? Symbol
          defaults = []

          if object.class.respond_to?(:i18n_parent_names) &&
              !object.class.i18n_parent_names.empty?

            names = object.class.i18n_parent_names
            until names.empty?
              defaults << ["errors", names.join("."), "parameters", path_elements.join("."), @value.to_s].reject do |item|
                item.nil? || item == ""
              end.join(".").to_sym
              names.pop
            end
          end

          unless path_elements.empty?
            defaults << :"errors.parameters.#{path_elements.join(".")}.#{@value}"
          end
          defaults << :"errors.parameters.#{@value}"

          key = defaults.shift
          I18n.translate(
            key,
            default: defaults,
            error_key: @value,
            parameter: path_elements.last
          )
        else
          "#{path_elements.join(".")} #{@value}".lstrip
        end
      end

      def ==(other)
        @value == if other.is_a?(self.class)
          other.value
        else
          other
        end
      end
      alias_method :eql?, :==

      def hash
        @value.hash
      end

      def inspect
        "(Error) #{@value.inspect}"
      end
    end

    def initialize
      @tree = Sycamore::Tree.new
    end

    def_delegators :@tree, :empty?

    def add(error: {}, errors: {}, object: nil)
      trees = []
      [error, errors].each do |h|
        tree = nil
        tree = if h.is_a? Metaractor::Errors
          Sycamore::Tree.from(h.instance_variable_get(:@tree))
        else
          Sycamore::Tree.from(normalize_error_hash(h))
        end

        unless tree.empty?
          if tree.nodes.any? { |node| tree.strict_leaf?(node) }
            raise ArgumentError, "Invalid hash!"
          end

          trees << tree
        end
      end

      trees.each do |tree|
        tree.each_path do |path|
          node = path.node
          unless node.is_a?(Error)
            node = Error.new(
              value: path.node,
              object: object
            )
          end

          @tree[path.parent] << node
        end
      end
      @tree.compact
    end

    def full_messages(tree = @tree)
      messages = []
      tree.each_path do |path|
        messages << message_from_path(path)
      end

      messages
    end
    alias_method :to_a, :full_messages

    def full_messages_for(*path)
      child_tree = @tree.fetch_path(path)

      if child_tree.strict_leaves?
        child_tree = @tree.fetch_path(path[0..-2])
      end

      full_messages(child_tree)
    end

    def dig(*path)
      result = @tree.dig(*path)

      if result.strict_leaves?
        unwrapped_enum(result.nodes)
      else
        unwrapped_tree(result).to_h
      end
    end
    alias_method :[], :dig

    def include?(*elements)
      if elements.size == 1 &&
          elements.first.is_a?(Hash)
        unwrapped_tree.include?(*elements)
      elsif elements.all? { |e| e.is_a? String }
        full_messages.include?(*elements)
      else
        elements.all? do |element|
          @tree.include_path?(element)
        end
      end
    end

    def slice(*paths)
      new_tree = Sycamore::Tree.new

      paths.each do |path|
        if @tree.include_path?(path)
          new_tree[path] = @tree[path].dup
        end
      end

      unwrapped_tree(new_tree).to_h
    end

    def to_h(unwrap: true)
      if unwrap
        unwrapped_tree.to_h
      else
        @tree.to_h
      end
    end
    alias_method :to_hash, :to_h

    def inspect
      str = "<##{self.class.name}: "

      if !empty?
        str << "Errors:\n"
        str << Metaractor.format_hash(to_h(unwrap: false))
        str << "\n"
      end

      str << ">"
      str
    end

    private

    def message_from_path(path)
      path_elements = []
      path.parent&.each_node do |node|
        unless node == :base
          path_elements << node.to_s
        end
      end

      path.node.generate_message(path_elements: path_elements)
    end

    def unwrapped_tree(orig_tree = @tree)
      tree = Sycamore::Tree.new
      orig_tree.each_path do |path|
        node = path.node
        if node.is_a? Error
          node = node.value
        end

        tree[path.parent] << node
      end

      tree
    end

    def unwrapped_enum(orig)
      orig.map do |element|
        if element.is_a? Error
          element.value
        else
          element
        end
      end
    end

    def normalize_error_hash(hash)
      deep_transform_values_in_object(hash, &method(:transform_delegator))
    end

    def transform_delegator(value)
      if value.is_a?(Delegator)
        if value.respond_to?(:to_hash)
          deep_transform_values_in_object(value.to_hash, &method(:transform_delegator))
        elsif value.respond_to?(:to_a)
          deep_transform_values_in_object(value.to_a, &method(:transform_delegator))
        else
          value
        end
      else
        value
      end
    end

    # Lifted from Rails
    def deep_transform_values_in_object(object, &block)
      case object
      when Hash
        object.transform_values { |value| deep_transform_values_in_object(value, &block) }
      when Array
        object.map { |e| deep_transform_values_in_object(e, &block) }
      else
        yield(object)
      end
    end
  end
end

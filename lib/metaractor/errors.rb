require 'sycamore'
require 'forwardable'
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
          I18n.translate(
            :"errors.#{}.parameters.#{path_elements.join('.')}.#{@value}",
            attribute: @value
          )
        else
          "#{path_elements.join('.')} #{@value}".lstrip
        end
      end

      def ==(other)
        if other.is_a?(self.class)
          @value == other.value
        else
          @value == other
        end
      end
      alias eql? ==

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
        if h.is_a? Metaractor::Errors
          tree = Sycamore::Tree.from(h.instance_variable_get(:@tree))
        else
          tree = Sycamore::Tree.from(h)
        end

        unless tree.empty?
          if tree.nodes.any? {|node| tree.strict_leaf?(node) }
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
    alias to_a full_messages

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
    alias [] dig

    def include?(*elements)
      if elements.size == 1 &&
          elements.first.is_a?(Hash)
        unwrapped_tree.include?(*elements)
      else
        if elements.all? {|e| e.is_a? String }
          full_messages.include?(*elements)
        else
          elements.all? do |element|
            @tree.include_path?(element)
          end
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

    def inspect
      str = "<##{self.class.name}: "

      if !self.empty?
        str << "Errors:\n"
        str << Metaractor::FailureOutput.format_hash(to_h(unwrap: false))
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

  end
end

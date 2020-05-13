require 'sycamore'
require 'forwardable'
module Metaractor
  class Errors
    extend Forwardable

    def initialize
      @tree = Sycamore::Tree.new
    end

    def_delegators :@tree, :to_h, :empty?

    def add(error: {}, errors: {})
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
        @tree.add(tree)
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
        result.nodes
      else
        result.to_h
      end
    end
    alias [] dig

    def include?(*elements)
      if elements.size == 1 &&
          elements.first.is_a?(Hash)
        @tree.include?(*elements)
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

      new_tree.to_h
    end

    private

    def message_from_path(path)
      path_elements = []
      path.parent&.each_node do |node|
        unless node == :base
          path_elements << node.to_s
        end
      end

      "#{path_elements.join('.')} #{path.node.to_s}".lstrip
    end
  end
end

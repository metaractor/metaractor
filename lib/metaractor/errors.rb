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
    end

    def full_messages(tree = @tree)
      messages = []
      tree.each_path do |path|
        messages << message_from_path(path)
      end

      messages
    end

    def full_messages_for(*path)
      full_messages(@tree.fetch_path(path))
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

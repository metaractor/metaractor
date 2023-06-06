module Metaractor
  module Namespace
    # The following code is adapted from rails.

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def module_parent_name
        if defined?(@parent_name)
          @parent_name
        else
          parent_name = (name =~ /::[^:]+\z/) ? -$` : nil
          @parent_name = parent_name unless frozen?
          parent_name
        end
      end

      def module_parent_names
        parents = []
        if module_parent_name
          parents = module_parent_name.split("::")
        end
        parents
      end

      def i18n_parent_names
        module_parent_names.map { |name| underscore_module_name(name).to_sym }
      end

      private

      def underscore_module_name(camel_cased_word)
        return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
        word = camel_cased_word.to_s.gsub("::", "/")
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end
    end
  end
end

module Metaractor
  module Organizer
    def self.included(base)
      base.class_eval do
        include Metaractor
        include Interactor::Organizer
      end
    end
  end
end

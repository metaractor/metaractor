module Metaractor
  module FailureOutput
    def self.format_hash(hash)
      if @hash_formatter.nil?
        @hash_formatter = ->(hash){ hash.inspect }
      end

      @hash_formatter.call(hash)
    end

    def self.hash_formatter=(callable)
      @hash_formatter = callable
    end

    def to_s
      str = ''

      if !context.errors.empty?
        str << "Errors:\n"
        str << Metaractor::FailureOutput.format_hash(context.errors.to_h)
        str << "\n\n"
      end

      if !context._called.empty?
        str << "Previously Called:\n"
        context._called.each do |interactor|
          str << interactor.class.name.to_s
          str << "\n"
        end
        str << "\n"
      end

      str << "Context:\n"
      str << Metaractor::FailureOutput.format_hash(context.to_h.reject{|k,_| k == :errors})
      str
    end
  end
end

Interactor::Failure.send(:include, Metaractor::FailureOutput)

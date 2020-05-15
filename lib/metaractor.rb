require 'metaractor/version'
require 'interactor'
require 'metaractor/errors'
require 'metaractor/handle_errors'
require 'metaractor/context_errors'
require 'metaractor/parameters'
require 'metaractor/run_with_context'
require 'metaractor/context_validity'
require 'metaractor/chain_failures'
require 'metaractor/fail_from_context'
require 'metaractor/context_has_key'
require 'metaractor/failure_output'

module Metaractor
  def self.included(base)
    base.class_eval do
      include Interactor
      Metaractor.modules.each do |hsh|
        case hsh[:method]
        when :include
          include hsh[:module]
        when :prepend
          prepend hsh[:module]
        end
      end
    end
  end

  def self.configure
    yield self
  end

  def self.modules
    @modules ||= default_modules
  end

  def self.modules=(mods)
    @modules = mods
  end

  def self.default_modules
    [
      { module: Metaractor::HandleErrors, method: :include },
      { module: Metaractor::Parameters, method: :include },
      { module: Metaractor::RunWithContext, method: :include },
      { module: Metaractor::ChainFailures, method: :include }
    ]
  end

  def self.include_module(mod)
    modules << { module: mod, method: :include }
  end

  def self.prepend_module(mod)
    modules << { module: mod, method: :prepend }
  end

  def self.format_hash(hash)
    if @hash_formatter.nil?
      @hash_formatter = default_hash_formatter
    end

    @hash_formatter.call(hash)
  end

  def self.default_hash_formatter
    ->(hash){ hash.inspect }
  end

  def self.hash_formatter
    @hash_formatter
  end

  def self.hash_formatter=(callable)
    @hash_formatter = callable
  end
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metaractor/version'

Gem::Specification.new do |spec|
  spec.name          = 'metaractor'
  spec.version       = Metaractor::VERSION
  spec.license       = 'Apache-2.0'
  spec.authors       = ['Ryan Schlesinger']
  spec.email         = ['ryan@outstand.com']

  spec.summary       = %q{Adds parameter validation and error control to interactor}
  spec.metadata      = {
    "homepage_uri" => "https://github.com/outstand/metaractor",
    "source_code_uri" => "https://github.com/outstand/metaractor"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'interactor', '~> 3.1'
  spec.add_runtime_dependency 'outstand-sycamore', '0.4.0'
  spec.add_runtime_dependency 'i18n', '~> 1.8'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'awesome_print', '~> 1.8'
  spec.add_development_dependency 'pry-byebug', '~> 3.9'
  spec.add_development_dependency 'activemodel', '~> 6.1'
end

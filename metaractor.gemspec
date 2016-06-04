# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metaractor/version'

Gem::Specification.new do |spec|
  spec.name          = 'metaractor'
  spec.version       = Metaractor::VERSION
  spec.authors       = ['Ryan Schlesinger']
  spec.email         = ['ryan@outstand.com']

  spec.summary       = %q{Adds parameter validation and error control to interactor}
  spec.homepage      = 'https://github.com/outstand/metaractor'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'interactor', '~> 3.1'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
end

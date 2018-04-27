# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sandthorn/version'

Gem::Specification.new do |spec|
  spec.name          = "sandthorn"
  spec.version       = Sandthorn::VERSION
  spec.authors       = ["Lars Krantz", "Morgan Hallgren", "Jesper Josefsson"]
  spec.email         = ["lars.krantz@alaz.se", "morgan.hallgren@gmail.com", "jesper.josefsson@gmail.com"]
  spec.description   = %q{Event sourcing gem}
  spec.summary       = %q{Event sourcing gem}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.0'


  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "gem-release"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "autotest-standalone"
  spec.add_development_dependency "sqlite3"  
  spec.add_development_dependency "coveralls"
#  spec.add_development_dependency "sandthorn_driver_sequel", ">= 4.0"
end

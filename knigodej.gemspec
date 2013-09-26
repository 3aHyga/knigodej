# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knigodej/version'

Gem::Specification.new do |spec|
   spec.name          = "knigodej"
   spec.version       = Knigodej::VERSION
   spec.authors       = ["Malo Skrylevo"]
   spec.email         = ["majioa@yandex.ru"]
   spec.description   = %q{Knigodej gem is a tool to make a PDF, and DJVU books from the XCF (GIMP image) source}
   spec.summary       = %q{Knigodej gem is a tool to make a PDF, and DJVU books from the XCF (GIMP image) source}
   spec.homepage      = ""
   spec.license       = "MIT"

   spec.files         = `git ls-files`.split($/)
   spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
   spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
   spec.require_paths = ["lib"]

   spec.add_runtime_dependency 'micro-optparse'
   spec.add_runtime_dependency 'mini_magick', '~> 3.6.0'
   spec.add_runtime_dependency 'prawn'

   spec.add_development_dependency "bundler", "~> 1.3"
   spec.add_development_dependency "rake"

   spec.requirements << 'djvu-utils'
end

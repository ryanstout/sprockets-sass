# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'sprockets/sass/version'

Gem::Specification.new do |s|
  s.name        = 'sprockets-sass'
  s.version     = Sprockets::Sass::VERSION
  s.authors     = ['Pete Browne']
  s.email       = ['me@petebrowne.com']
  s.homepage    = 'http://github.com/petebrowne/sprockets-sass'
  s.summary     = %q{Better Sass integration with Sprockets 2.0}
  s.description = %q{When using Sprockets 2.0 with Sass you will eventually run into a pretty big issue. `//= require` directives will not allow Sass mixins, variables, etc. to be shared between files. So you'll try to use `@import`, and that'll also blow up in your face. `sprockets-sass` fixes all of this by creating a Sass::Importer that is Sprockets aware.}

  s.rubyforge_project = 'sprockets-sass'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split('\n').map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency             'sprockets',         '~> 2.0'
  s.add_dependency             'tilt',              '~> 2.0.1'
  s.add_development_dependency 'appraisal',         '~> 0.5'
  s.add_development_dependency 'rspec',             '~> 2.13'
  s.add_development_dependency 'test_construct',    '~> 2.0'
  s.add_development_dependency 'sprockets-helpers', '~> 1.0'
  s.add_development_dependency 'sass',              '~> 3.3'
  s.add_development_dependency 'compass',           '~> 1.0.0.alpha.19'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
end

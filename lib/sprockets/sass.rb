require 'sprockets'
require 'sprockets/sass/version'
require 'sprockets/engines'
require 'sprockets/sass/sass_template'
require 'sprockets/sass/scss_template'
require 'awesome_print'

module Sprockets
  module Sass
    autoload :CacheStore, 'sprockets/sass/cache_store'
    autoload :Compressor, 'sprockets/sass/compressor'
    autoload :Importer,   'sprockets/sass/importer'

    class << self
      # Global configuration for `Sass::Engine` instances.
      attr_accessor :options

      # When false, the asset path helpers provided by
      # sprockets-helpers will not be added as Sass functions.
      # `true` by default.
      attr_accessor :add_sass_functions
    end

    @options = {}
    @add_sass_functions = true
  end

    if Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('3.0')
      require 'sprockets/sass/sass_processor'
      require 'sprockets/sass/scss_processor'

      unregister_preprocessor 'text/css', DirectiveProcessor

      register_engine '.sass', Sass::SassProcessor, mime_type: 'text/css'
      register_engine '.scss', Sass::ScssProcessor, mime_type: 'text/css'
    else
      register_engine '.sass', Sass::SassTemplate
      register_engine '.scss', Sass::ScssTemplate
    end
end

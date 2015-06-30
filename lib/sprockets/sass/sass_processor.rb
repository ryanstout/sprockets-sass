require 'rack/utils'
require 'sprockets/autoload'
require 'uri'

module Sprockets
  module Sass
    class SassProcessor < Sprockets::SassProcessor
      # Get the default, global Sass options. Start with Compass's
      # options, if it's available.

      def initialize
        super
        @per_file_engines = {}
      end

      def default_sass_options
        if defined?(Compass)
          merge_sass_options Compass.sass_engine_options.dup, Sprockets::Sass.options
        else
          Sprockets::Sass.options.dup
        end
      end

      # Merges two sets of `Sass::Engine` options, prepending
      # the `:load_paths` instead of clobbering them.
      def merge_sass_options(options, other_options)
        if (load_paths = options[:load_paths]) && (other_paths = other_options[:load_paths])
          other_options[:load_paths] = other_paths + load_paths
        end
        options.merge other_options
      end

      def get_cache_store(input)
        @cache_store ||= Sprockets::SassProcessor::CacheStore.new(input[:cache], @cache_version)
      end

      def sass_options(input, context)
        merge_sass_options(default_sass_options, {
          filename: input[:filename],
          syntax: self.class.syntax,
          cache_store: get_cache_store(input),
          load_paths: input[:environment].paths,
          importer: get_importer,
          sprockets: {
            context: context,
          }
        })
      end

      def create_sass_engine_for(input, context)
        unless @per_file_engines[input[:filename]]
          puts '-- storing engine for '+input[:filename]
          @per_file_engines[input[:filename]] = Autoload::Sass::Engine.new(input[:data], sass_options(input, context))
        end

        return @per_file_engines[input[:filename]]
      end

      def get_sass_engine_for(filename)
        puts '-- get engine for '+filename
        # ap @per_file_engines.keys
        @per_file_engines[filename] || nil
      end

      def call(input)
        puts 'processor::call '+input[:filename]

        context = input[:environment].context_class.new(input)

        engine = create_sass_engine_for(input, context)

        css = Utils.module_include(Autoload::Sass::Script::Functions, @functions) do
          engine.render
        end

        # Track all imported files
        sass_dependencies = Set.new([input[:filename]])
        engine.dependencies.map do |dependency|
          # puts 'dep '+dependency
          sass_dependencies << dependency.options[:filename]

          context.metadata[:dependencies] << URIUtils.build_file_digest_uri(dependency.options[:filename])
        end

        context.metadata.merge(data: css, sass_dependencies: sass_dependencies)
      end

      def get_importer
        @importer ||= Importer.new(self)
      end
    end
  end
end
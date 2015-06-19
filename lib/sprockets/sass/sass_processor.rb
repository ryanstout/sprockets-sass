require 'rack/utils'
require 'sprockets/autoload'
require 'uri'

module Sprockets
  module Sass
    class SassProcessor < Sprockets::SassProcessor
      def call(input)
        context = input[:environment].context_class.new(input)

        options = {
          filename: input[:filename],
          syntax: self.class.syntax,
          cache_store: Sprockets::SassProcessor::CacheStore.new(input[:cache], @cache_version),
          load_paths: input[:environment].paths,
          importer: get_importer,
          sprockets: {
            context: context,
            environment: input[:environment],
            dependencies: context.metadata[:dependencies]
          }
        }

        engine = Autoload::Sass::Engine.new(input[:data], options)

        css = Utils.module_include(Autoload::Sass::Script::Functions, @functions) do
          engine.render
        end

        # Track all imported files
        sass_dependencies = Set.new([input[:filename]])
        engine.dependencies.map do |dependency|
          sass_dependencies << dependency.options[:filename]
          context.metadata[:dependencies] << URIUtils.build_file_digest_uri(dependency.options[:filename])
        end

        context.metadata.merge(data: css, sass_dependencies: sass_dependencies)
      end

      def get_importer
        Importer.new
      end
    end
  end
end
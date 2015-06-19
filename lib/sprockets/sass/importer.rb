require 'sass/importers/base'
require 'pathname'

module Sprockets
  module Sass
    class Importer < ::Sass::Importers::Base
      GLOB = /\*|\[.+\]/

      # @see Sass::Importers::Base#find_relative
      def find_relative(path, base_path, options)
        if path =~ GLOB
          engine_from_glob(path, base_path, options)
        else
          engine_from_path(path, base_path, options)
        end
      end

      # @see Sass::Importers::Base#find
      def find(path, options)
        engine_from_path(path, nil, options)
      end

      # @see Sass::Importers::Base#mtime
      def mtime(path, options)
        if pathname = resolve(path)
          pathname.mtime
        end
      rescue Errno::ENOENT
        nil
      end

      # @see Sass::Importers::Base#key
      def key(path, options)
        path = Pathname.new(path)
        ["#{self.class.name}:#{path.dirname.expand_path}", path.basename]
      end

      # @see Sass::Importers::Base#to_s
      def to_s
        "#{self.class.name}:#{context.pathname}"
      end

      protected

      # Create a Sass::Engine from the given path.
      def engine_from_path(path, base_path, options)
        context = options[:sprockets][:context]
        pathname = resolve(context, path, base_path) or return nil
        context.depend_on pathname
        ::Sass::Engine.new evaluate(context, pathname), options.merge(
          :filename => pathname.to_s,
          :syntax   => syntax(pathname),
          :importer => self
        )
      end

      # Create a Sass::Engine that will handle importing
      # a glob of files.
      def engine_from_glob(glob, base_path, options)
        context = options[:sprockets][:context]
        imports = resolve_glob(context, glob, base_path).inject('') do |imports, path|
          context.depend_on path
          relative_path = path.relative_path_from Pathname.new(base_path).dirname
          imports << %(@import "#{relative_path}";\n)
        end
        return nil if imports.empty?
        ::Sass::Engine.new imports, options.merge(
          :filename => base_path.to_s,
          :syntax   => :scss,
          :importer => self
        )
      end

      # Finds an asset from the given path. This is where
      # we make Sprockets behave like Sass, and import partial
      # style paths.
      def resolve(context, path, base_path)
        possible_files(context, path, base_path).each do |file|
          found = context.environment.resolve(file.to_s, {accept: context.content_type})

          return found if found
        end

        nil
      end

      # Finds all of the assets using the given glob.
      def resolve_glob(context, glob, base_path)
        base_path      = Pathname.new(base_path)
        path_with_glob = base_path.dirname.join(glob).to_s

        Pathname.glob(path_with_glob).sort.select do |path|
          path != context.pathname && context.asset_requirable?(path)
        end
      end

      # Returns all of the possible paths (including partial variations)
      # to attempt to resolve with the given path.
      def possible_files(context, path, base_path)
        path      = Pathname.new(path)
        base_path = Pathname.new(base_path).dirname
        paths     = [ path, partialize_path(path) ]

        # Find base_path's root
        env_root_paths = context.environment.paths.map {|p| Pathname.new(p) }
        root_path = env_root_paths.detect do |env_root_path|
          base_path.to_s.start_with?(env_root_path.to_s)
        end
        root_path ||= Pathname.new(context.root_path)

        # Add the relative path from the root, if necessary
        if path.relative? && base_path != root_path
          relative_path = base_path.relative_path_from(root_path).join path
          paths.unshift(relative_path, partialize_path(relative_path))
        end

        paths.compact
      end

      # Returns the partialized version of the given path.
      # Returns nil if the path is already to a partial.
      def partialize_path(path)
        if path.basename.to_s !~ /\A_/
          Pathname.new path.to_s.sub(/([^\/]+)\Z/, '_\1')
        end
      end

      # Returns the Sass syntax of the given path.
      def syntax(path)
        path.to_s.include?('.sass') ? :sass : :scss
      end

      # Returns the string to be passed to the Sass engine. We use
      # Sprockets to process the file, but we remove any Sass processors
      # because we need to let the Sass::Engine handle that.
      def evaluate(context, path)
        asset = context.environment[path]

        return File.binread(asset.filename)
        # puts '===================================='
        # ap asset.source
        # puts '===================================='
        # context.evaluate(path, :processors => processors)
      end
    end
  end
end

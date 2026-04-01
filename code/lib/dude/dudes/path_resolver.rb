module Dude
  module Dudes
    class PathResolver
      def expand_target(readlink_result, dudes_dir)
        path = readlink_result.chomp('/')
        return path if path.start_with?('/')

        resolve_relative(dudes_dir, path)
      end

      private

      def resolve_relative(dudes_dir, path)
        parts = dudes_dir.split('/').reject(&:empty?)
        path.split('/').each { |comp| process_component(parts, comp) }
        '/' + parts.join('/')
      end

      def process_component(parts, component)
        parts.pop if component == '..'
        parts << component unless component == '.' || component == '..'
      end
    end
  end
end

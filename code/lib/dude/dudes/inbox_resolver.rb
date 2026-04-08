module Dude
  module Dudes
    class InboxResolver
      def resolve(name)
        link = File.join(::Dude::GLOBAL_DIR, name)
        raise "dude '#{name}' not found" unless File.symlink?(link)

        target = File.readlink(link).chomp('/')
        File.join(target, 'dudes', 'inbox.json')
      end
    end
  end
end

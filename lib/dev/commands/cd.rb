require 'dev'

module Dev
  module Commands
    FZY = begin
      basename = RUBY_PLATFORM =~ /darwin/ ? 'fzy_darwin' : 'fzy_linux'
      File.expand_path("vendor/#{basename}", ROOT)
    end
    class Cd < Dev::Command
      def call(args, _name)
        raise(Abort, 'one arg required') unless args.size == 1
        arg = args.first
        scores, stat = CLI::Kit::System.capture2(FZY, '--show-matches', arg, stdin_data: repos.join("\n"))
        raise(Abort, 'fzy failed') unless stat.success?
        target = scores.lines.first
        IO.new(9).puts("chdir:#{target}")
      end

      def repos
        # Src directory should follow a tree format of source_host > owner > repo
        # ie ~/src/some-host.com/an-organization/a-repo

        hosts = absolute_subdirectories(src)

        orgs = hosts.map do |host|
          absolute_subdirectories(host)
        end.flatten

        repos = orgs.map do |org|
          absolute_subdirectories(org)
        end.flatten

        repos
      end

      def self.help
        'TODO'
      end

      private

      def src
        File.expand_path(Dev::Config.projects_path)
      end

      def absolute_subdirectories(path)
        Dir.children(path)
        .map { |entry| File.join(path, entry) }
        .select { |entry| File.directory?(entry) }
      end
    end
  end
end

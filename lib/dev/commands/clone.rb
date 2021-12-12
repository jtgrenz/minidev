require('dev')
require('fileutils')

module Dev
  module Commands
    class Clone < Dev::Command
      CLONE_METHODS = %w(https ssh)
      GIT_PROVIDERS = %w(github.com gitlab.com)

      class GitProvider

        attr_accessor :repo, :git_provider, :clone_method
        def initialize(repo:, clone_method:, git_provider:)
          @repo = repo
          @git_provider = git_provider
          @clone_method = normalize_clone_method(clone_method)
        end

        def clone_uri
          case clone_method
          when :ssh
            "git@#{git_provider}:/#{repo}.git"
          when :https
            "https://#{git_provider}/#{repo}.git"
          end
        end

        def target
          File.expand_path(File.join(Dev::Config.projects_path, git_provider, repo))
        end

        def clone
          CLI::Kit::System.system('git', 'clone', clone_uri, target)
        end

        private

        def normalize_clone_method(clone_method)
          return :ssh if clone_method.include?('git@') || clone_method.include?('ssh')
          return :https if clone_method.include?('https')

          raise(Abort, "unknown value #{clone_method} for config default.clone_method. Valid options are #{CLONE_METHODS}")
        end
      end

      attr_reader :default_clone_method, :default_provider

      def initialize
        super
        @default_clone_method = Dev::Config.get('default', 'clone_method', default: 'https')
        @default_provider = Dev::Config.get('default', 'git_provider', default: 'github.com')
        check_defaults
      end

      def call(args, _name)
        raise(Abort, 'one arg required') unless args.size == 1

        arg = args.first
        provider = build_provider(arg)
        raise(Abort, "clone failed") unless provider.clone.success?
        IO.new(9).puts("chdir:#{provider.target}")
      end

      def self.help
        'TODO'
      end

      private

      def build_provider(arg)
        if arg =~ %r{(https://|git@).*}
          match_data = arg.match(%r{(?<clone_method>https:\/\/|git@)(?<provider>[^:\/]*)(\/|:)(?<repo>.*)})
          clone_method = Dev::Config.get('default', 'clone_method', default: match_data[:clone_method])
          repo = match_data[:repo].gsub('.git', '')
          return GitProvider.new(repo: repo, clone_method: clone_method , git_provider: match_data[:provider])
        elsif arg =~ %r{.*/.*}
          return GitProvider.new(repo: arg, clone_method: @default_clone_method, git_provider: @default_provider)
        else
          return GitProvider.new(repo: "#{default_account}/#{arg}", clone_method: @default_clone_method, git_provider: @default_provider)
        end
      end

      def default_account
        account = Dev::Config.get('default', 'account')
        raise(Abort, 'account/repo both required unless default.account is set in config') unless account
        account
      end

      def check_defaults
        raise(Abort, "unknown value #{default_clone_method} for config default.clone_method. Valid options are #{CLONE_METHODS}") unless CLONE_METHODS.include?(default_clone_method)
        raise(Abort, "unknown value #{default_provider} for config default.git_provider. Valid options are #{GIT_PROVIDERS}") unless GIT_PROVIDERS.include?(default_provider)
      end
    end
  end
end

require 'dev'

module Dev
  module Support
    class Config < CLI::Kit::Config

      def projects_path
        get('default', 'src_dir') || '~/src'
      end
    end
  end
end


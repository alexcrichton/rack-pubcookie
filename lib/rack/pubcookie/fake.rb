module Rack
  module Pubcookie
    class Fake

      def initialize app, username
        @app, @username = app, username
      end

      def call env
        env['REMOTE_USER'] = @username
        @app.call env
      end

    end
  end
end

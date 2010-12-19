module Rack
  module Pubcookie

    # This Rack interface is meant to be used in development. It mocks out
    # pubcookie authentication by always setting the REMOTE_USER variable to
    # a specific username given to the constructor.
    #
    # This is not meant to be used in production obviously...
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

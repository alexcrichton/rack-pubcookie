require 'rack'

require 'rack/pubcookie/version'
require 'rack/pubcookie/auth'

module Rack
  class Pubcookie

    include Auth

    def initialize app, options
      @app = app
      self.pubcookie_options = options
    end

    def call env
      request = Rack::Request.new env

      if request.path == '/auth/pubcookie'
        response = Rack::Response.new login_page_html
      else
        request.env['REMOTE_USER'] = extract_username request
        status, headers, body = @app.call(request.env)
        response = Rack::Response.new body, status, headers

        set_pubcookie! request, response
      end

      response.finish
    end

  end
end

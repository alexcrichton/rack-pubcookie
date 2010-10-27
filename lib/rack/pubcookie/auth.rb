require 'active_support/core_ext/object/to_query'
require 'openssl'
require 'base64'

module Rack
  module Pubcookie
    class Auth

      def initialize app, login_server, host, appid
        @app = app
        @login_server = login_server # https://webiso.andrew.cmu.edu/
        @host = host # scheduleman.org
        @appid = appid
      end

      def call env
        @env = env

        if request.path == '/auth/pubcookie'
          [200, {'Content-Type' => 'text/html'}, [login_page_html]]
        else
          @app.call env
        end
      end

      def request
        @request ||= Rack::Request.new(@env)
      end

      protected

      # For a better description on what each of these values are, go to
      # https://wiki.doit.wisc.edu/confluence/display/WEBISO/Pubcookie+Granting+Request+Interface
      def request_login_arguments
        args = {
          :one          => @host,     # FQDN of our host
          :two          => @appid,    # Our AppID for pubcookie
          :three        => 1,         # ?
          :four         => 'a5',      # Version/encryption?
          :five         => 'GET',     # method, even though we lie?
          :six          => @host,     # our host domain name
          :seven        => '/auth/pubcookie/callback', # Where to return
          :eight        => '',        # ?
          :nine         => 1,         # Probably should be different...
          :hostname     => @host,     # Pubcookie needs it 3 times...
          :referer      => '(null)',  # Just don't bother
          :sess_re      => 0,         # Don't force re-authentication
          :pre_sess_tok => Kernel.rand(2000000), # Just a random 32bit number
          :flag         => 0,         # ?
          :file         => ''         # ?
        }

        args[:seven] = Base64.encode64(args[:seven]).chomp
        args
      end

      def login_page_html
        input_val = Base64.encode64 request_login_arguments.to_query

        # Curious why exactly this template? This was taken from the pubcookie
        # source. We just do the same thing here...
        <<-HTML
<html>
<head></head>
<body onLoad="document.relay.submit()">
  <form method='post' action="https://#{@login_server}" name='relay'>
    <input type='hidden' name='pubcookie_g_req' value="#{input_val}">
    <input type='hidden' name='post_stuff' value="">
    <input type='hidden' name='relay_url' value="https://#{@host}/auth/pubcookie/callback">
    <noscript>
      <p align='center'>You do not have Javascript turned on,   please click the button to continue.
      <p align='center'>
        <input type='submit' name='go' value='Continue'>
      </p>
    </noscript>
  </form>
</html>
HTML
      end

    end
  end
end

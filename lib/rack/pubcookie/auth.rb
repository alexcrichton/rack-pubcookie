require 'rack/utils'
require 'openssl'
require 'base64'

module Rack
  module Pubcookie
    class Auth

      include AES
      include DES

      def initialize app, login_server, host, appid, keyfile, granting_cert,
          opts = {}
        @app          = app
        @login_server = login_server
        @host         = host
        @appid        = appid
        @keyfile      = keyfile
        @granting = OpenSSL::X509::Certificate.new(::File.read(granting_cert))
        ::File.open(@keyfile, 'rb'){ |f| @key = f.read.bytes.to_a }

        @options = opts
        @options[:expires_after] = 24 * 3600 # 24 hrs
      end

      def call env
        request = Rack::Request.new env

        if request.path == '/auth/pubcookie'
          response = Rack::Response.new login_page_html
        else
          request.env['REMOTE_USER'] = extract_username request
          status, headers, body = @app.call(request.env)
          response = Rack::Response.new body, status, headers

          if !request.params['pubcookie_g'].nil? &&
              request.params['pubcookie_g'] != request.cookies['pubcookie_g']
            response.set_cookie 'pubcookie_g', :path => '/', :secure => true,
              :value => request.params['pubcookie_g']
          end
        end

        response.finish
      end

      protected

      def extract_username request
        # If coments below refer to a URL, they mean this one:
        # http://svn.cac.washington.edu/viewvc/pubcookie/trunk/src/pubcookie.h?view=markup
        cookie = request.params['pubcookie_g'] || request.cookies['pubcookie_g']

        return nil if cookie.nil?

        bytes  = Base64.decode64(cookie).bytes.to_a
        index2 = bytes.pop
        index1 = bytes.pop

        if true # TODO: should check for aes vs des encryption...
          decrypted = des_decrypt bytes, index1, index2
        else
          decrypted = aes_decrypt bytes, index1, index2
        end

        return nil if decrypted.nil?

        # These values are all from the pubcookie source. For more info, see the
        # above URL. The relevant size definitions are around line 42 and the
        # struct begins on line 69 ish
        user, version, appsrvid, appid, type, creds, pre_sess_tok,
          create_ts, last_ts = decrypted.unpack('A42A4A40A128aaINN')

        create_ts = Time.at create_ts
        last_ts   = Time.at last_ts

        if Time.now < create_ts + @options[:expires_after] && appid == @appid
          user
        else
          nil
        end
      end

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
        query = request_login_arguments.to_a.map{ |k, v|
          "#{k}=#{Rack::Utils.escape v}"
        }.join '&'
        input_val = Base64.encode64 query
        input_val = input_val.gsub("\n", '')

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

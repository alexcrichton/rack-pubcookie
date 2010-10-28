require 'active_support/core_ext/object/to_query'
require 'openssl'
require 'openssl/evp'
require 'base64'

module Rack
  module Pubcookie
    class Auth

      def initialize app, login_server, host, appid, keyfile, granting_cert
        @app          = app
        @login_server = login_server
        @host         = host
        @appid        = appid
        @keyfile      = keyfile
        @granting = OpenSSL::X509::Certificate.new(::File.read(granting_cert))
        ::File.open(@keyfile, 'rb'){ |f| @key = f.read.bytes.to_a }
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

        # In the URL above, the initial IVEC is defined around line 63 and for
        # some reason only the first byte is used in the xor'ing
        ivec = @key[index2, 8]
        ivec = ivec.map{ |i| i ^ 0x4c }

        key = @key[index1, 8]

        c  = OpenSSL::Cipher.new('des-cfb')
        c.decrypt
        c.key = key.map(&:chr).join
        c.iv  = ivec.map(&:chr).join

        # This should be offset by the size of the granting key? Not sure...
        signature = c.update(bytes[0..127].map(&:chr).join)
        decrypted = c.update(bytes[128..-1].map(&:chr).join)

        # These values are all from the pubcookie source. For more info, see the
        # above URL. The relevant size definitions are around line 42 and the
        # struct begins on line 69 ish

        if OpenSSL::EVP.verify_md5(@granting, signature, decrypted)
          user     = decrypted[0, 41].gsub(/\u0000+$/, '')
          version  = decrypted[42, 4].gsub(/\u0000+$/, '')
          appsrvid = decrypted[46, 40].gsub(/\u0000+$/, '')
          appid    = decrypted[86, 128].gsub(/\u0000+$/, '')

          appid == @appid ? user : nil
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
        input_val = Base64.encode64 request_login_arguments.to_query
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

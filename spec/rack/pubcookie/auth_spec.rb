require 'spec_helper'

describe Rack::Pubcookie::Auth do

  include Rack::Test::Methods

  def app
    Rack::Builder.new {
      use Rack::Pubcookie::Auth, 'example.com', 'myhost.com', 'testappid',
        Rack::Test.fixture_path + '/test.com',
        Rack::Test.fixture_path + '/granting.crt'
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['llama']] }
    }.to_app
  end

  describe "a valid session" do
    before :each do
      Time.stub(:at).and_return Time.now
    end

    it "renders a login page to send a request to the login server" do
      Kernel.stub(:rand).and_return(100)

      get '/auth/pubcookie'

      doc   = Nokogiri::HTML(last_response.body)
      forms = doc.css('form')
      forms.length.should == 1
      form = forms.first

      form['method'].should == 'post'
      form['action'].should == 'https://example.com'

      inputs = form.css('input[type=hidden]')
      inputs.size.should == 3

      inputs[0]['name'].should == 'pubcookie_g_req'
      pubcookie_g = Rack::Utils.parse_query Base64.decode64(inputs[0]['value'])
      pubcookie_g.should == {
        "one" => "myhost.com", "two" => "testappid", "three" => "1",
        "four" => "a5", "five" => "GET", "six" => "myhost.com",
        "seven" => Base64.encode64('/auth/pubcookie/callback').chomp,
        "eight" => "", "nine" => "1", "hostname" => "myhost.com",
        "referer" => "(null)", "sess_re" => "0", "pre_sess_tok" => "100",
        "flag" => "0", "file" => ""
      }

      inputs[1]['name'].should == 'post_stuff'
      inputs[1]['value'].should == ''

      inputs[2]['name'].should == 'relay_url'
      inputs[2]['value'].should == 'https://myhost.com/auth/pubcookie/callback'
    end

    it "parses the response cookie and sets the REMOTE_USER varible" do
      post '/auth/pubcookie/callback',
        'pubcookie_g' => Rack::Test.sample_response

      last_request.env['REMOTE_USER'].should == 'testing'
    end

    it "authenticates based off of the cookie given" do
      escaped = Rack::Utils.escape Rack::Test.sample_response
      set_cookie "pubcookie_g=#{escaped}"

      post '/auth/pubcookie/callback'

      last_request.env['REMOTE_USER'].should == 'testing'
    end

    it "sets a cookie based on the response from the login server" do
      escaped = Rack::Utils.escape Rack::Test.sample_response

      post '/auth/pubcookie/callback',
        'pubcookie_g' => Rack::Test.sample_response

      last_response.headers['Set-Cookie'].should eql(
        "pubcookie_g=#{escaped}; path=/; secure")
    end

    it "doesn't have the Set-Cookie header when authenticated by a cookie" do
      set_cookie "pubcookie_g=#{Rack::Test.sample_response}"

      post '/auth/pubcookie/callback'

      last_response.headers['Set-Cookie'].should be_nil
    end
  end

  describe "invalid authentications" do
    it "doesn't tamper with any variables if no authentication is present" do
      post '/auth/pubcookie/callback'

      last_response.headers['Set-Cookie'].should be_nil
      last_request.env['REMOTE_USER'].should be_nil
    end

    it "doesn't allow an expired valid authentication cookie" do
      # The login cookie contains a struct with the issued at timestamp as a
      # 32 bit integer. We use Time.at on the integer to get the time object for
      # when it was issued. By stubbing that, we can simulate the cookie being
      # issued 2 days ago without having to work around different cookies and
      # such
      Time.stub(:at).and_return Time.now - 48 * 3600

      post '/auth/pubcookie/callback',
        'pubcookie_g' => Rack::Test.sample_response

      last_request.env['REMOTE_USER'].should be_nil
    end
  end

  describe "an invalid signature" do
    def app
      Rack::Builder.new {
        use Rack::Pubcookie::Auth, 'example.com', 'myhost.com', 'testappid',
          Rack::Test.fixture_path + '/test.com',
          Rack::Test.fixture_path + '/invalid.crt'
        run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['llama']] }
      }.to_app
    end

    it "realizes the cookie has an invalid signature and discards the cookie" do
      post '/auth/pubcookie/callback',
        'pubcookie_g' => Rack::Test.sample_response

      last_request.env['REMOTE_USER'].should be_nil
    end
  end

end

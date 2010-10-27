require 'spec_helper'

describe Rack::Pubcookie::Auth do

  include Rack::Test::Methods

  def app
    Rack::Builder.new {
      use Rack::Pubcookie::Auth, 'example.com', 'myhost.com', 'testappid'
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['oh boy']] }
    }.to_app
  end

  def session
    last_request.env
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

end

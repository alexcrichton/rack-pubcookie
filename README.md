rack-pubcookie
==============

This is an implementation of the [pubcookie](http://pubcookie.org) protocol over Rack in Ruby.

Installation
------------

In a Gemfile: `gem 'rack-pubcookie'`

Otherwise: `gem install rack-pubcookie`

The gem can be required through either `rack-pubcookie` or `rack/pubcookie`

Usage
-----

To use pubcookie in your application, you'll need a few things.

* The URL of the login server
* A FQDN for which you have an SSL certificate and which the server is running off of
* An application ID (normally this is gotten from the login server provider)
* A keyfile. This is generated via the `keyclient` program provided by the official pubcookie source code. Currently there is no equivalent of said program in this gem, so you'll need to create this on another server or acquire it from your login provider
* The granting certificate. This is the x509 .crt/cert file which your login provider signs all cookies with. You need a copy of the public key (.crt) file to verify cookies
* An SSL-enabled server. Pubcookie will not redirect to an `http` host, but rather only an `https` one

Once these six pieces have been obtained, you can then use it like this:

<pre>
# This is located in config.ru
require 'rack/pubcookie'

use Rack::Pubcookie::Auth, @login_server, @hostname, @appid, @keyfile_path,
  @granting_certificate_path

# @login_server => 'login.example.com[:port]' (port optional)
# @hostname     => 'myapp.example.com[:port]' (port optional)
# @appid        => 'myappid'
# @keyfile_path => '/path/to/key/file'
# @granting_certificate_path => '/path/to/granting.crt'

run Your::Application
</pre>

Then, in your application, if you need the user authenticated and they're not currently, then you need to redirect them to `/auth/pubcookie`. This will then redirect the user to the login server (with some extra variables and things).

Once authenticated, the user will then be redirected to `/auth/pubcookie/callback`. If we are able to decrypt the response from the login server, the `REMOTE_USER` environment variable will be set in the request for use.

The response to `/auth/pubcookie/callback` will also set the session cookie for the current user. It has the `secure` flag, so it will only be sent on HTTPS connections.

Also, every request where the pubcookie session cookie is present, the `REMOTE_USER` variable will be set. This only applies to `https` connections before the expiration date of the cookie

License
----
Copyright (c) 2010 Alex Crichton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

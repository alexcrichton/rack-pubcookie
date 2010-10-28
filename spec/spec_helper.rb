require 'rubygems'
require 'bundler'
Bundler.require :default, :development

require 'rspec/core'
require 'rack/test'

RSpec.configure do |c|
  c.color_enabled = true
end

module Rack
  module Test

    def self.fixture_path
      ::File.expand_path('../fixtures', __FILE__)
    end

    def self.sample_response
      # This data was pre-constructed using DES encryption and a dummy test
      # server. Slightly magical, but the setup was just a test pubcookie server
      # and a local nginx server handling SSL requests proxing to a small app.
      # All of the certificates were signed correctly and whatnot and everything
      # worked out somehow eventually to the cookie below.
      "6zDplapzi0TAIG3mzfff99EII888gkBUo2fywh1f52ff6Hq4QlrlZ6HbMVSUph7X0x9q0JxbZIfcVjRB9ir92WoihBBRuM4ES/MkqfZs2coB8KeNWQMBls+Nl19IYXv7dJoFjQ8lfBkzgV8BzQ9CIETQqT6AF+7vZBdUddKwu+9kCVtaVk4Pl7Vl0TfzYHCp831xrNxepLx6xtSg33l05CsXtaTVXhm/9khsU8/ONb5xEu21YM5D2OjM1cTUvan3bbCnRHVpqrq1fo8+cNeufP7lUGPoMEjEzjTTLpEXTsfvshX8Ojgl2mowxhbGIkC+MRJuKEAQV9kvdnFmdMWFnMo2j5KJzeiNoRvWg0DfVon8Ya7JAAt+PkpnGu6FwzOHYvYoj+7t1HJIW/iyjXfXjOhzRDSY22YYEOIgqfodCzSURi5hrmUwSsAtXTmpqHrTDN4smIfEUQvQAIMlEhnH2ocSztbJFw=="
    end

  end
end

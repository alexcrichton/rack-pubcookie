# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'rack/pubcookie/version'

Gem::Specification.new do |s|
  s.name        = 'rack-pubcookie'
  s.version     = Rack::Pubcookie::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alex Crichton']
  s.email       = ['alex@alexcrichton.com']
  s.homepage    = 'http://github.com/alexcrichton/rack-pubcookie'
  s.summary     = 'An implentation of pubcookie based on Rack'
  s.description = 'Pubcookie for ruby!'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.extensions    = ['ext/openssl/extconf.rb']
  s.require_paths = ['lib', 'ext']
  
  s.add_dependency 'rack'
end

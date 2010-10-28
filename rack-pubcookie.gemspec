# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'rack/pubcookie/version'

Gem::Specification.new do |s|
  s.name        = 'rack-pubcookie'
  s.version     = Rack::Pubcookie::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Alex Crichton']
  s.email       = ['alex@alexcrichton.com']
  s.homepage    = 'http://github.com/alexcrichton/rack-pubcookie'
  s.summary     = 'An implentation of pubcookie based on Rack in Ruby'
  s.description = 'Pubcookie finally leaves the world of apache!'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.extensions    = ['ext/openssl/extconf.rb']
  s.require_paths = ['lib', 'ext']

  s.add_dependency 'rack'
  s.add_dependency 'activesupport'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'nokogiri'
end

require 'rubygems'
require 'bundler'
Bundler.require :default, :development

require 'rspec/core'
require 'rack/pubcookie'
require 'rack/test'

RSpec.configure do |c|
  c.color_enabled = true
end

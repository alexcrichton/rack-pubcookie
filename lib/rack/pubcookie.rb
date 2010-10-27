require 'rack'

module Rack
  module Pubcookie
    autoload :VERSION, 'rack/pubcookie/version'

    autoload :Auth, 'rack/pubcookie/auth'
  end
end

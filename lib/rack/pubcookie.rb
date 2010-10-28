require 'rack'

module Rack
  module Pubcookie
    autoload :VERSION, 'rack/pubcookie/version'

    autoload :Auth, 'rack/pubcookie/auth'
    autoload :AES, 'rack/pubcookie/aes'
    autoload :DES, 'rack/pubcookie/des'
  end
end

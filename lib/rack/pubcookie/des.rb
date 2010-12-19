module Rack
  module Pubcookie
    module DES

      def des_decrypt bytes, index1, index2
        # In the URL of #extract_username, the initial IVEC is defined around
        # line 63 and for some reason only the first byte is used in the xor'ing
        ivec = @key[index2, 8]
        ivec = ivec.map{ |i| i ^ 0x4c }

        key = @key[index1, 8]

        c  = OpenSSL::Cipher.new('des-cfb')
        c.decrypt
        c.key = key.pack('c*')
        c.iv  = ivec.pack('c*')

        # This should be offset by the size of the granting key? Not sure...
        signature = c.update(bytes[0..127].pack('c*'))
        decrypted = c.update(bytes[128..-1].pack('c*'))

        if @granting.public_key.verify(OpenSSL::Digest::MD5.new, signature, decrypted)
          decrypted
        else
          nil
        end
      end

    end
  end
end

require 'mkmf'

if RUBY_VERSION =~ /1\.9/
  $CFLAGS << ' -DRUBY_19'
end

if have_header('openssl/evp.h') && have_header('openssl/x509.h')
  create_makefile('evp')
end

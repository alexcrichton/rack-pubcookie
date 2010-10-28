#include <openssl/evp.h>
#include <openssl/x509.h>
#include <ruby.h>

#define GetX509(obj, x509) Data_Get_Struct(obj, X509, x509)

#ifndef RUBY_19
# define RSTRING_LEN(s) (RSTRING(s)->len)
# define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif

VALUE evp_verify_md5(VALUE self, VALUE cert, VALUE signature, VALUE str) {
  X509 *x509;
  EVP_MD_CTX ctx;
  EVP_PKEY *key;

  GetX509(cert, x509);
  key = X509_extract_key(x509);

  EVP_VerifyInit(&ctx, EVP_md5());
  EVP_VerifyUpdate(&ctx, RSTRING_PTR(str), RSTRING_LEN(str));

  int ret_val = EVP_VerifyFinal(&ctx,
        (unsigned char*) RSTRING_PTR(signature),
        (unsigned int)   RSTRING_LEN(signature),
        key);

  return ret_val == 1 ? Qtrue : Qfalse;
}

Init_evp() {
  VALUE cOpenSSL = rb_define_module("OpenSSL");
  VALUE cEVP     = rb_define_module_under(cOpenSSL, "EVP");

  rb_define_singleton_method(cEVP, "verify_md5", evp_verify_md5, 3);
}

#include <hbapi.h>
#include <hbapiitm.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <string>
#include <vector>
#include <ctime>

// Base64url encode (sin padding, RFC 4648)
static std::string base64url_encode( const unsigned char* data, size_t len )
{
   static const char* b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
   std::string result;
   int i = 0;
   unsigned char buf3[3], buf4[4];
   while( len-- )
   {
      buf3[ i++ ] = *data++;
      if( i == 3 )
      {
         buf4[0] = ( buf3[0] & 0xfc ) >> 2;
         buf4[1] = ( ( buf3[0] & 0x03 ) << 4 ) + ( ( buf3[1] & 0xf0 ) >> 4 );
         buf4[2] = ( ( buf3[1] & 0x0f ) << 2 ) + ( ( buf3[2] & 0xc0 ) >> 6 );
         buf4[3] = buf3[2] & 0x3f;
         for( int j = 0; j < 4; j++ ) result += b64[ buf4[j] ];
         i = 0;
      }
   }
   if( i )
   {
      for( int j = i; j < 3; j++ ) buf3[j] = 0;
      buf4[0] = ( buf3[0] & 0xfc ) >> 2;
      buf4[1] = ( ( buf3[0] & 0x03 ) << 4 ) + ( ( buf3[1] & 0xf0 ) >> 4 );
      buf4[2] = ( ( buf3[1] & 0x0f ) << 2 ) + ( ( buf3[2] & 0xc0 ) >> 6 );
      for( int j = 0; j < i + 1; j++ ) result += b64[ buf4[j] ];
   }
   // Convertir a base64url
   for( char& c : result )
   {
      if( c == '+' ) c = '-';
      else if( c == '/' ) c = '_';
   }
   return result;
}

static std::string base64url_encode_str( const std::string& s )
{
   return base64url_encode( (const unsigned char*) s.c_str(), s.size() );
}

// Firma RSA-SHA256 y devuelve base64url
static std::string rsa_sign( const std::string& msg, const std::string& pem_key )
{
   BIO* bio = BIO_new_mem_buf( pem_key.c_str(), -1 );
   EVP_PKEY* pkey = PEM_read_bio_PrivateKey( bio, nullptr, nullptr, nullptr );
   BIO_free( bio );

   if( !pkey ) return "";

   EVP_MD_CTX* ctx = EVP_MD_CTX_new();
   EVP_DigestSignInit( ctx, nullptr, EVP_sha256(), nullptr, pkey );
   EVP_DigestSignUpdate( ctx, msg.c_str(), msg.size() );

   size_t siglen = 0;
   EVP_DigestSignFinal( ctx, nullptr, &siglen );
   std::vector<unsigned char> sig( siglen );
   EVP_DigestSignFinal( ctx, sig.data(), &siglen );

   EVP_MD_CTX_free( ctx );
   EVP_PKEY_free( pkey );

   return base64url_encode( sig.data(), siglen );
}

// HB_FUNC: recibe client_email, private_key, scope — devuelve JWT string
HB_FUNC( CPP_GENERATE_JWT )
{
   const char* email     = hb_parc( 1 );
   const char* pem_key   = hb_parc( 2 );
   const char* scope     = hb_parc( 3 );

   if( !email || !pem_key || !scope )
   {
      hb_retc( "" );
      return;
   }

   long now = (long) time( nullptr );
   long exp = now + 3600;

   std::string header  = "{\"alg\":\"RS256\",\"typ\":\"JWT\"}";
   std::string payload = "{\"iss\":\"" + std::string(email) + "\","
                         "\"scope\":\"" + std::string(scope) + "\","
                         "\"aud\":\"https://oauth2.googleapis.com/token\","
                         "\"iat\":" + std::to_string(now) + ","
                         "\"exp\":" + std::to_string(exp) + "}";

   std::string b64h = base64url_encode_str( header );
   std::string b64p = base64url_encode_str( payload );
   std::string signing_input = b64h + "." + b64p;
   std::string signature = rsa_sign( signing_input, std::string(pem_key) );

   std::string jwt = signing_input + "." + signature;
   hb_retc( jwt.c_str() );
}
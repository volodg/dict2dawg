 
#include <iostream>
#include <fstream>

#include "testUtils.h"

std::string pathToDawgDict()
{
   NSString* str_ = [ [ NSBundle mainBundle ] pathForResource: @"ok_dict" ofType: @"dawg" ];
   const char* cstr_ = [ str_ cStringUsingEncoding: NSASCIIStringEncoding ];
   return std::string( cstr_ );
}

std::string pathToRuDawgDict()
{
   NSString* str_ = [ [ NSBundle mainBundle ] pathForResource: @"ru_dict" ofType: @"dawg" ];
   const char* cstr_ = [ str_ cStringUsingEncoding: NSASCIIStringEncoding ];
   return std::string( cstr_ );
}

std::string pathToBadPlainDict()
{
   NSString* str_ = [ [ NSBundle mainBundle ] pathForResource: @"bad_dict" ofType: @"txt" ];
   const char* cstr_ = [ str_ cStringUsingEncoding: NSASCIIStringEncoding ];
   return std::string( cstr_ );
}

std::string pathToNormalPlainDict()
{
   NSString* str_ = [ [ NSBundle mainBundle ] pathForResource: @"ok_dict" ofType: @"txt" ];
   const char* cstr_ = [ str_ cStringUsingEncoding: NSASCIIStringEncoding ];
   return std::string( cstr_ );
}

std::string pathToPlainRuDict()
{
   NSString* str_ = [ [ NSBundle mainBundle ] pathForResource: @"ru_dict" ofType: @"txt" ];
   const char* cstr_ = [ str_ cStringUsingEncoding: NSASCIIStringEncoding ];
   return std::string( cstr_ );
}

static const std::string whiteSpaces( " \f\n\r\t\v" );

static void trimRight( std::string& str,
                      const std::string& trimChars = whiteSpaces )
{
   std::string::size_type pos = str.find_last_not_of( trimChars );
   str.erase( pos + 1 );    
}

const std::vector< std::string > vectorWithPlainDict( const std::string& file )
{
   std::ifstream ifs( file.c_str() );

   std::vector< std::string > result_;
   std::string temp_;
   while( getline( ifs, temp_ ) )
   {
      trimRight( temp_, "\n\r");

      if ( temp_.size() != 0 )
      {
         std::transform(temp_.begin(), temp_.end(), temp_.begin(), toupper);
         result_.push_back( temp_ );
      }
   }

   return result_;
}

const std::set< std::string > setWithPlainDict( const std::string& file )
{
   std::ifstream ifs( file.c_str() );

   std::set< std::string > result;
   std::string temp;
   while( getline( ifs, temp ) )
   {
      trimRight( temp, "\n\r");

      if ( temp.size() != 0 )
      {
         std::transform(temp.begin(), temp.end(), temp.begin(), toupper);
         result.insert( temp );
      }
   }

   return result;
}

#import <Foundation/Foundation.h>

extern "C" {
#include "dict2dawg.h"
}

#include "Dawg2Dict.h"
#include <fstream>
#include <map>
#include <set>

const std::string whiteSpaces( " \f\n\r\t\v" );

void trimRight( std::string& str,
               const std::string& trimChars = whiteSpaces );

void trimRight( std::string& str,
               const std::string& trimChars )
{
   std::string::size_type pos = str.find_last_not_of( trimChars );
   str.erase( pos + 1 );    
}

const std::set< std::string > setWithDict( const std::string& file );
const std::set< std::string > setWithDict( const std::string& file )
{
   std::ifstream ifs( file.c_str() );

   std::set< std::string > result;
   std::string temp;
   while( getline( ifs, temp ) )
   {
      trimRight( temp, "\n\r");

      if ( temp.size() != 0 )
         result.insert( temp );
   }

   return result;
}

const std::vector< std::string > vectorWithDict( const std::string& file );
const std::vector< std::string > vectorWithDict( const std::string& file )
{
   std::ifstream ifs( file.c_str() );

   std::vector< std::string > result;
   std::string temp;
   while( getline( ifs, temp ) )
   {
      trimRight( temp, "\n\r");

      if ( temp.size() != 0 )
         result.push_back( temp );
   }

   return result;
}

void testAllDict( const Dawg2Dict& dict );
void testAllDict( const Dawg2Dict& dict )
{
   std::vector< std::string > sowpods = vectorWithDict( std::string( "/Users/vgor/Player.txt" ) );
   std::vector< std::string >::iterator it = sowpods.begin();

   NSLog( @"start test" );
   while( it != sowpods.end() )
   {
      if ( !dict.contains( *it ) )
      {
         NSLog( @"error: say that not contains: %s", (*it).c_str() );
         break;
      }
      else
      {
//         NSLog( @"OK: %s", temp.c_str() );
      }

      ++it;
   }
   NSLog( @"end test" );
}

void testDifferenceDict( const Dawg2Dict& dict );
void testDifferenceDict( const Dawg2Dict& dict )
{
   std::set< std::string > playerDict = setWithDict( std::string( "/Users/vgor/Player.txt" ) );
   std::set< std::string > sowpodsDict = setWithDict( std::string( "/Users/vgor/sowpods.txt" ) );

   std::vector< std::string > result;

   set_difference ( sowpodsDict.begin(), sowpodsDict.end()
                   , playerDict.begin(), playerDict.end()
                   , std::inserter( result, result.end() ) );

   std::vector< std::string >::iterator it_ = result.begin();
   for ( ; it_ != result.end(); ++it_ )
   {
      if ( dict.contains( *it_ ) )
      {
         NSLog( @"error: say that contains: %s", (*it_).c_str() );
         break;
      }
      else
      {
         //NSLog( @"OK: %s", temp.c_str() );
      }
   }
}

int main (int argc, const char * argv[])
{
   @autoreleasepool
   {
      NSLog( @"Hello, World" );
//      dict2dawg_converter( "/Users/vgor/Player.txt" );

      Dawg2Dict dict;

      dict.load( std::string("/Users/vgor/Traditional_Dawg_For_Word-List.dat") );

      //GTODO test words from origin dict
      testDifferenceDict( dict );
      testAllDict( dict );

      NSLog( @"test done" );
//      NSLog( @"tst0: %d", dict.contains( std::string("AALS") ) );
//      NSLog( @"tst0: %d", dict.contains( std::string("/Users/vgor/Traditional_Dawg_For_Word-List.dat") ) );
//      NSLog( @"tst1: %d", dict.contains( std::string("ZZZ") ) );
//      NSLog( @"tst1: %d", dict.contains( std::string("apple") ) );
//      NSLog( @"tst0: %d", dict.contains( std::string("apple1") ) );
//      NSLog( @"tst0: %d", dict.contains( std::string("appleb") ) );
//      NSLog( @"tst0: %d", dict.contains( std::string("appl") ) );
      //"/Users/vgor/sowpods.txt"
   }
   return 0;
}


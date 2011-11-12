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
   std::ifstream ifs( "/Users/vgor/Player.txt" );

   std::set< std::string > result;
   std::string temp;
   while( getline( ifs, temp ) )
   {
      trimRight( temp, "\n\r");
      result.insert( temp );
   }

   return result;
}

void testAllDict( const Dawg2Dict& dict );
void testAllDict( const Dawg2Dict& dict )
{
   std::ifstream ifs( "/Users/vgor/Player.txt" );

   std::string temp;
   while( getline( ifs, temp ) )
   {
      trimRight( temp, "\n\r");
      if ( !dict.contains( temp ) )
      {
         NSLog( @"error: say that not contains: %s", temp.c_str() );
         break;
      }
      else
      {
         NSLog( @"OK: %s", temp.c_str() );
      }
   }
}

void testDifferenceDict( const Dawg2Dict& dict );
void testDifferenceDict( const Dawg2Dict& dict )
{
   std::set< std::string > playerDict = setWithDict( std::string( "/Users/vgor/Player.txt" ) );
   std::set< std::string > sowpodsDict = setWithDict( std::string( "/Users/vgor/sowpods.txt" ) );

   std::vector< std::string > result;

   set_difference ( sowpodsDict.begin(), sowpodsDict.end()
                   , playerDict.begin(), playerDict.end()
                   , result.begin());
   
   for (  )
   {
      
   }
}

int main (int argc, const char * argv[])
{
   @autoreleasepool
   {
      NSLog(@"Hello, World: %lu", sizeof(uint32_t) );
//      dict2dawg_converter( "/Users/vgor/Player.txt" );

      Dawg2Dict dict;

      dict.load( std::string("/Users/vgor/Traditional_Dawg_For_Word-List.dat") );

      //GTODO test words from origin dict
      testDifferenceDict( dict );

      NSLog( @"test done" );
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


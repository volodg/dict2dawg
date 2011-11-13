#import <Foundation/Foundation.h>

extern "C"
{
#include "dict2dawg.h"
#include "line_counter.h"
}

#include <set>
#include <string>
#include <fstream>

static const std::string whiteSpaces( " \f\n\r\t\v" );

static void trimRight( std::string& str,
                      const std::string& trimChars = whiteSpaces )
{
   std::string::size_type pos = str.find_last_not_of( trimChars );
   str.erase( pos + 1 );    
}

void setWithPlainDict(  )
{
   std::ifstream ifs( "/Users/vgor/dict2dawg/resources/short_dict.txt" );

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

   ////

   std::ofstream ofs( "/Users/vgor/short_dict.txt" );

   std::set< std::string >::iterator it_ = result.begin();
   while ( it_ != result.end() )
   {
      ofs << *it_ << std::endl;
      ++it_;
   }

//   return result;
}

int main (int argc, const char * argv[])
{
   @autoreleasepool
   {
//      setWithPlainDict();
      dict2dawg_converter( "/Users/vgor/dict2dawg/resources/short_dict.txt"
                          , "/Users/vgor/Traditional_Dawg.dat"
                          , "/Users/vgor/Traditional_Dawg_Report.txt" );
   }
   return 0;
}

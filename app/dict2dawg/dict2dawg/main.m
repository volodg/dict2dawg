#import <Foundation/Foundation.h>

#include "dict2dawg.h"
#include "line_counter.h"

int main (int argc, const char * argv[])
{
   @autoreleasepool
   {
      dict2dawg_converter( "/Users/vgor/dict2dawg/resources/ok_dict.txt"
                          , "/Users/vgor/Traditional_Dawg.dat"
                          , "/Users/vgor/Traditional_Dawg_Report.txt" );
   }
   return 0;
}


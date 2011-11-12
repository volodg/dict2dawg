#import <Foundation/Foundation.h>

#include "dict2dawg.h"

int main (int argc, const char * argv[])
{
   @autoreleasepool
   {
      NSString* const path_ = [ [ NSBundle mainBundle ] pathForResource: @"ok_dict" ofType: @"txt" ];

      dict2dawg_converter( [ path_ cStringUsingEncoding: NSASCIIStringEncoding ]
                          , "/Users/vgor/Traditional_Dawg.dat"
                          , "/Users/vgor/Traditional_Dawg_Report.txt" );
   }
   return 0;
}


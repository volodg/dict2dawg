#include <Dawg2Dict/Dawg2Dict.h>

@interface Dawg2DictTest : GHTestCase
@end

@implementation Dawg2DictTest

-(NSString*)pathToDawgDict
{
   return [ [ NSBundle mainBundle ] pathForResource: @"ok_dict" ofType: @"dawg" ];
}

-(const char*)cStringPathToDawgDict
{
   return [ [ self pathToDawgDict ] cStringUsingEncoding: NSASCIIStringEncoding ];
}

-(std::string)stdStringPathToDawgDict
{
   return std::string( [ self cStringPathToDawgDict ] );
}

-(void)testDictLoad
{
   Dawg2Dict dict;

   bool result_ = dict.load( [ self stdStringPathToDawgDict ] );

   GHAssertTrue( result_, @"dict should be loaded" );
}

@end

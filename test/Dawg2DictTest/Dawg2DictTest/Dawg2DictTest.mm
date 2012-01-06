#include <Dawg2Dict/Dawg2Dict.h>

#include "testUtils.h"

#import <JFFUtils/NSString/NSString+WideString.h>

@interface Dawg2DictTest : GHTestCase
@end

@implementation Dawg2DictTest

-(void)testDictLoad
{
   Dawg2Dict dict;

   bool result_ = dict.load( pathToDawgDict() );

   GHAssertTrue( result_, @"dict should be loaded" );
}

-(void)testAllWordsFromDict
{
   std::vector< std::string > palin_dict_ = vectorWithPlainDict( pathToNormalPlainDict() );
   GHAssertTrue( palin_dict_.size() != 0, @"dict should be loaded" );

   std::vector< std::string >::iterator it_ = palin_dict_.begin();

   Dawg2Dict dict;
   bool result_ = dict.load( pathToDawgDict() );
   GHAssertTrue( result_, @"dict should be loaded" );

    while( it_ != palin_dict_.end() )
    {
        const char* ptr_ = it_->c_str();
        NSString* str_ = [ NSString stringWithCString: ptr_ encoding: NSUTF8StringEncoding ];

        if ( !dict.contains( str_ ) )
        {
            GHFail( @"Word: %s should be in dict", it_->c_str() );
            break;
        }
        ++it_;
    }
}

-(void)testDictsDifference
{
   std::set< std::string > normalDict = setWithPlainDict( pathToNormalPlainDict() );
   std::set< std::string > badDict    = setWithPlainDict( pathToBadPlainDict   () );

   std::vector< std::string > result;

   set_difference ( badDict.begin(), badDict.end()
                   , normalDict.begin(), normalDict.end()
                   , std::inserter( result, result.end() ) );

    Dawg2Dict dict;
    bool result_ = dict.load( pathToDawgDict() );
    GHAssertTrue( result_, @"dict should be loaded" );

    std::vector< std::string >::iterator it_ = result.begin();
    for ( ; it_ != result.end(); ++it_ )
    {
        NSString* str_ = [ NSString stringWithCString: it_->c_str() encoding: NSUTF8StringEncoding ];

        if ( dict.contains( str_ ) )
        {
            GHFail( @"Word: %s should not be in dict", (*it_).c_str() );
            break;
        }
    }
}

-(void)testRuDictLoad
{
    Dawg2Dict dict;

    bool result_ = dict.ruLoad( pathToRuDawgDict() );

    GHAssertTrue( result_, @"dict should be loaded" );
}

-(void)testAllWordsFromRuDict
{
    std::vector< std::string > palin_dict_ = vectorWithPlainDict( pathToPlainRuDict() );
    GHAssertTrue( palin_dict_.size() != 0, @"dict should be loaded" );

    std::vector< std::string >::iterator it_ = palin_dict_.begin();

    Dawg2Dict dict;
    bool result_ = dict.ruLoad( pathToRuDawgDict() );
    GHAssertTrue( result_, @"dict should be loaded" );

    while( it_ != palin_dict_.end() )
    {
        NSString* str_ = [ NSString stringWithCString: it_->c_str() encoding: NSWindowsCP1251StringEncoding ];

        if ( !dict.contains( str_ ) )
        {
            GHFail( @"Word: %@ should be in dict", str_ );
            break;
        }
        ++it_;
    }
}

-(void)testSomeEnglishWords
{
   Dawg2Dict dict;
   bool result_ = dict.load( pathToDawgDict() );
   GHAssertTrue( result_, @"dict should be loaded" );

   GHAssertTrue( dict.contains( @"father" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"FATHER" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"FaThEr" ), @"папа should be in dict" );

   GHAssertFalse( dict.contains( @"fatherZ" ), @"папа should not be in dict" );
   GHAssertFalse( dict.contains( @"FATHERz" ), @"папа should not be in dict" );

   GHAssertTrue( dict.contains( @"carving" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"CARVING" ), @"папа should be in dict" );

   GHAssertFalse( dict.contains( @"carvingssd" ), @"папа should be in dict" );
   GHAssertFalse( dict.contains( @"carvi" ), @"папа should be in dict" );
}

-(void)testSomeRussianWords
{
   Dawg2Dict dict;
   bool result_ = dict.ruLoad( pathToRuDawgDict() );
   GHAssertTrue( result_, @"dict should be loaded" );

   GHAssertTrue( dict.contains( @"папа" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"ПАПА" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"пАпА" ), @"папа should be in dict" );

   GHAssertFalse( dict.contains( @"папаЯ" ), @"папа should not be in dict" );
   GHAssertFalse( dict.contains( @"ПАПАя" ), @"папа should not be in dict" );

   GHAssertTrue( dict.contains( @"набедренник" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"НАБЕДРЕННИК" ), @"папа should be in dict" );

   GHAssertFalse( dict.contains( @"набедренникк" ), @"папа should be in dict" );
   GHAssertFalse( dict.contains( @"набедр" ), @"папа should be in dict" );
}

-(void)testShorrRussianDict
{
   Dawg2Dict dict;
   bool result_ = dict.ruLoad( pathToShortRuDawgDict() );
   GHAssertTrue( result_, @"dict should be loaded" );

   GHAssertTrue( dict.contains( @"папа" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"ПАПА" ), @"папа should be in dict" );
   GHAssertTrue( dict.contains( @"пАпА" ), @"папа should be in dict" );

   GHAssertTrue( dict.contains( @"легкомыслие" ), @"папа should be in dict" );

   GHAssertFalse( dict.contains( @"папаЯ" ), @"папа should not be in dict" );
   GHAssertFalse( dict.contains( @"ПАПАя" ), @"папа should not be in dict" );

   GHAssertFalse( dict.contains( @"набедренник" ), @"папа should be in dict" );
   GHAssertFalse( dict.contains( @"НАБЕДРЕННИК" ), @"папа should be in dict" );

   GHAssertFalse( dict.contains( @"набедренникк" ), @"папа should be in dict" );
   GHAssertFalse( dict.contains( @"набедр" ), @"папа should be in dict" );
}

-(void)testRuDictsDifference
{
   std::set< std::string > ruDict = setWithPlainDict( pathToRuPlainDict() );
   std::set< std::string > shortRuDict = setWithPlainDict( pathToShortRuPlainDict() );

   std::vector< std::string > result;

   set_difference ( ruDict.begin(), ruDict.end()
                   , shortRuDict.begin(), shortRuDict.end()
                   , std::inserter( result, result.end() ) );

   Dawg2Dict dict;
   bool result_ = dict.ruLoad( pathToShortRuDawgDict() );
   GHAssertTrue( result_, @"dict should be loaded" );

   std::vector< std::string >::iterator it_ = result.begin();
   for ( ; it_ != result.end(); ++it_ )
   {
       NSString* str_ = [ NSString stringWithCString: it_->c_str() encoding: NSWindowsCP1251StringEncoding ];
      if ( dict.contains( str_ ) )
      {
         GHFail( @"Word: %s should not be in dict", (*it_).c_str() );
         break;
      }
   }
}

@end

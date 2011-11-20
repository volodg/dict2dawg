#include <Dawg2Dict/Dawg2Dict.h>

#include "testUtils.h"

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
   //GTODO fix this word also
   std::string skip_word_( "ZZZ" );

   std::vector< std::string > palin_dict_ = vectorWithPlainDict( pathToNormalPlainDict() );
   GHAssertTrue( palin_dict_.size() != 0, @"dict should be loaded" );

   std::vector< std::string >::iterator it = palin_dict_.begin();

   Dawg2Dict dict;
   bool result_ = dict.load( pathToDawgDict() );
   GHAssertTrue( result_, @"dict should be loaded" );

   while( it != palin_dict_.end() )
   {
      if ( *it != skip_word_
          && !dict.contains( *it ) )
      {
         GHFail( @"Word: %s should be in dict", (*it).c_str() );
         break;
      }
      ++it;
   }
}

-(void)testDictsDifference
{
   std::set< std::string > normalDict = setWithPlainDict( pathToNormalPlainDict() );
   std::set< std::string > badDict = setWithPlainDict( pathToBadPlainDict() );

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
      if ( dict.contains( *it_ ) )
      {
         GHFail( @"Word: %s should not be in dict", (*it_).c_str() );
         break;
      }
   }
}

-(void)testRuDictLoad
{
   Dawg2Dict dict;

   bool result_ = dict.load( pathToRuDawgDict() );

   GHAssertTrue( result_, @"dict should be loaded" );
}

-(void)testAllWordsFromRuDict
{
   //GTODO fix this word also
   //ящурка
   std::string skip_word_( [ @"ящурка" cStringUsingEncoding: NSWindowsCP1251StringEncoding ] );

   std::vector< std::string > palin_dict_ = vectorWithPlainDict( pathToPlainRuDict() );
   GHAssertTrue( palin_dict_.size() != 0, @"dict should be loaded" );

   std::vector< std::string >::iterator it = palin_dict_.begin();

   Dawg2Dict dict;
   bool result_ = dict.ruLoad( pathToRuDawgDict() );
   GHAssertTrue( result_, @"dict should be loaded" );

   while( it != palin_dict_.end() )
   {
      if ( *it != skip_word_
          && !dict.contains( *it ) )
      {
         GHFail( @"Word: %s should be in dict", (*it).c_str() );
         break;
      }
      ++it;
   }
}

@end

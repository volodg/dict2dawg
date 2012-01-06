#import <Foundation/Foundation.h>

#include <string>

@interface NSString (ToWideString)

+(NSString*)stringWithWideString:( const std::wstring& )str_;

-(std::wstring)toWideString;

@end

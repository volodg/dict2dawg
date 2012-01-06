#import "NSString+WideString.h"

@implementation NSString (ToWideString)

//see http://devmacosx.blogspot.com/2010/09/nsstring-to-wstring.html
+(NSString*)stringWithWideString:( const std::wstring& )str_
{
    NSString* pString = [ [ NSString alloc ]    
                         initWithBytes: (char*)str_.data()   
                                length: str_.size() * sizeof(wchar_t)   
                              encoding: NSUTF32LittleEndianStringEncoding ];   
    return pString;   
}  

-(std::wstring)toWideString
{
    NSData* data_ = [ self dataUsingEncoding : NSUTF32LittleEndianStringEncoding ];    
    return std::wstring ( (wchar_t*) [ data_ bytes ]
                         , [ data_ length] / sizeof ( wchar_t ) );
}

@end

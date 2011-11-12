#ifndef Dawg2DictTest_testUtils_h
#define Dawg2DictTest_testUtils_h

#include <string>
#include <vector>
#include <set>

std::string pathToDawgDict();
std::string pathToBadPlainDict();
std::string pathToNormalPlainDict();

const std::vector< std::string > vectorWithPlainDict( const std::string& file );
const std::set< std::string > setWithPlainDict( const std::string& file );

#endif

#ifndef DAWG2DICT_HEADER_H_INCLUDED
#define DAWG2DICT_HEADER_H_INCLUDED

#import <vector>
#import <string>

@class NSString;

class DawgNode
{
public:
   wchar_t letter;
   bool last_in_word;
   bool last_in_list;
   int32_t next_node;
public:
   bool unserialize( FILE* fp );
   bool ruUnserialize( FILE* fp );
};

//GTODO fails on contains( "ZZZ" )
class Dawg2Dict
{
    bool russian;
    std::vector<DawgNode> nodes;
    uint32_t next_node_for_char( uint32_t curr_node_index_, wchar_t letter, bool& last_in_word ) const;
public:
    bool load( const std::string& fname );
    bool ruLoad( const std::string& fname );

    bool contains( NSString* str_ ) const;
};

#endif //DAWG2DICT_HEADER_H_INCLUDED

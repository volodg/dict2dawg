#ifndef DAWG2DICT_HEADER_H_INCLUDED
#define DAWG2DICT_HEADER_H_INCLUDED

#import <vector>
#import <string>

class DawgNode
{
public:
   char letter;
   bool last_in_word;
   bool last_in_list;
   int32_t next_node;
public:
   void unserialize (FILE* fp);
};

//GTODO fails on contains( "ZZZ" )
class Dawg2Dict
{
   std::vector<DawgNode> nodes;
   uint32_t next_node_for_char( uint32_t curr_node_index_, char letter, bool& last_in_word ) const;
public:
   bool load( const std::string& fname );
   bool contains( const std::string& str ) const;
};

#endif //DAWG2DICT_HEADER_H_INCLUDED

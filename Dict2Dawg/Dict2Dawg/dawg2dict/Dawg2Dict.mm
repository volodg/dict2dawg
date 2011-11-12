#include "Dawg2Dict.h"

#import <string>

using std::string;
using std::vector;

void DawgNode::unserialize( FILE* fp )
{
   uint32_t bin_node_ = 0;
   if (fread(&bin_node_, sizeof(uint32_t), 1, fp) != 1) {
      NSLog( @"DawgNode::unserialize: read error." );
      return;
   }

   letter       = (bin_node_ & 0x3F) + 'A';
   next_node    = ( bin_node_ >> 8 ) - 1;
   last_in_word = bin_node_ & 0x80;
   last_in_list = bin_node_ & 0x40;
}

uint32_t Dawg2Dict::next_node_for_char( uint32_t curr_node_index_, char letter_, bool& out_last_in_word_ ) const
{
   DawgNode curr_node_ = nodes.at( curr_node_index_ );
   while ( !curr_node_.last_in_list && curr_node_.letter != letter_ )
   {
      curr_node_ = nodes.at( ++curr_node_index_ );
   }

   uint32_t result_ = -1;
   if ( curr_node_.letter == letter_ )
   {
      result_ = curr_node_.next_node;
      out_last_in_word_ = curr_node_.last_in_word;
   }

   return result_;
}

//bool isLastLetterInWord(  )

bool Dawg2Dict::contains( const std::string& str_ ) const
{
   const size_t str_size_ = str_.size();

   if ( str_size_ < 2 )
      return false;

   int curr_node_index_ = 0;
   bool last_in_word = false;

   uint index_ = 0;
   for( ; index_ < str_size_; ++index_ )
   {
      char curr_char_ = toupper( str_[index_] );
      curr_node_index_ = next_node_for_char( curr_node_index_, curr_char_, last_in_word );
      if ( -1 == curr_node_index_ )
      {
         ++index_;
         break;
      }
   }

   return last_in_word && ( index_ == str_size_ );
}

bool Dawg2Dict::load ( const std::string& fname )
{
   FILE* fp;
   uint32_t nsize;
   if ((fp = fopen(fname.c_str(), "rb")) == 0) {
      return false;
   }
   if (fread(&nsize, sizeof(uint32_t), 1, fp) != 1) {
      fclose(fp);
      return false;
   }
   nodes.resize(nsize);
   for (uint i=0; i<nsize; i++) {
      nodes[i].unserialize(fp);
   }
   fclose(fp);
   return true;
}

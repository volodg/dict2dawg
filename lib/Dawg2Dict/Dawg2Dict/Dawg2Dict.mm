#include "Dawg2Dict.h"

#import <string>

#import <JFFUtils/NSString/NSString+WideString.h>

using std::wstring;
using std::vector;

bool DawgNode::unserialize( FILE* fp )
{
   uint32_t bin_node_ = 0;
   if (fread(&bin_node_, sizeof(uint32_t), 1, fp) != 1) {
      NSLog( @"DawgNode::unserialize: read error." );
      return false;
   }

   letter       = (bin_node_ & 0x3F) + 'A';
   next_node    = ( bin_node_ >> 8 ) - 1;
   last_in_word = bin_node_ & 0x80;
   last_in_list = bin_node_ & 0x40;

   return true;
}

bool DawgNode::ruUnserialize( FILE* fp )
{
    uint32_t bin_node_ = 0;
    if (fread(&bin_node_, sizeof(uint32_t), 1, fp) != 1) {
        NSLog( @"DawgNode::unserialize: read error." );
        return false;
    }

    unsigned char tmp_ = (bin_node_ & 0x3F);
    
    if ( tmp_ == 33 )//ё
    {
        tmp_ = 168;
    }
    else
    {
        tmp_ = tmp_ + 192;
    }

    char strPtr_[2] = {0};
    strPtr_[0] = tmp_;

    NSString* tmpStr_ = [ [ NSString alloc ] initWithBytes: &tmp_
                                                    length: 1
                                                  encoding: NSWindowsCP1251StringEncoding ];

    this->letter = [ tmpStr_ characterAtIndex: 0 ];

    [ tmpStr_ release ];

    next_node    = ( bin_node_ >> 8 ) - 1;
    last_in_word = bin_node_ & 0x80;
    last_in_list = bin_node_ & 0x40;

    return true;
}

uint32_t Dawg2Dict::next_node_for_char( uint32_t curr_node_index_, wchar_t letter_, bool& out_last_in_word_ ) const
{
   out_last_in_word_ = false;

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

bool Dawg2Dict::contains( NSString* objecStr ) const
{
    std::wstring str_ = [ [ objecStr uppercaseString ] toWideString ];
    const size_t str_size_ = str_.size();

    int curr_node_index_ = 0;
    bool last_in_word = false;

    uint index_ = 0;
    for( ; index_ < str_size_; ++index_ )
    {
        wchar_t curr_char_ = str_[index_];
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
      if ( !nodes[i].unserialize(fp) )
         break;
   }
   fclose(fp);
   return true;
}

bool Dawg2Dict::ruLoad ( const std::string& fname )
{
   russian = true;

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
      if ( !nodes[i].ruUnserialize(fp) )
         break;
   }
   fclose(fp);
   return true;
}

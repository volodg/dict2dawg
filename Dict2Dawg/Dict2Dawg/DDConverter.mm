#import "DDConverter.h"

/* The line below is to protect against Bitnet mailer damage */
#define MOD %
/* This should be a Percent (for C Modulus) */ 

/* Blech. This file is a mess. Make it the first rewrite... */
#include "copyr.h"
/*****************************************************************************/
/*                                                                           */
/*      FILE : PACK.C                                                        */
/*                                                                           */
/*      Re-pack a dawg/trie data structure using Franklin Liang's            */
/*      algorithm for sparse matrix storage.  Final structure allows         */
/*      direct indexing into trie nodes, so is exceedingly fast at checking. */
/*      Unfortunately the trade off is that any algorithms which walk        */
/*      the data structure and generate words will take much longer          */
/*                                                                           */
/*              PACK <dawg file (inc .ext)> <pack file (inc .ext)>           */
/*                                                                           */
/*****************************************************************************/

/* Pending:
 
 see what closest gap between dawgptr + freenode is, and see whether we
 can save space by overlapping input & output arrays with a window between
 them.  Should get almost 50% of memory back.  Also, because of hacking
 around a bug some time back, I'm using an extra array (new_loc) for
 relocation of pointers, when in fact I could (and have in the past)
 managed to relocate them in situ with not much extra overhead.
 As I said, it needs a rewrite...
 
 */

/* Note: I tried one implementation of this which used bitsets to test
 whether two nodes were compatible.  In fact, it wasn't sufficiently
 faster to justify the extra space it used for the arrays of flags.
 Now I check for compatibility on the fly with lots of comparisons.
 I do however have a seperate byte array to flag whether a trie
 is based at any address.  There's probably a way of removing this.
 */

#include "grope.h"
#ifndef grope_h
/* If you don't have grope.h, create an empty one.
 These will do for a basic system: */
#undef KNOWS_VOID
#undef STDLIBS
#undef PROTOTYPES
#define SYS_ANY 1
#define COMPILER_ANY 1
#define SMALL_MEMORY 1 /*  To be defined if you have to generate
the data structure in bits. This will
certainly be true for any non-trivial
dictionary on MSDOS, or most home
micros with 1Mb Ram or under. */
#endif

#include <stdio.h>

/*#define RCHECK*/  /* Turn this back on if you have any problems. */

#include "dawg.h"
#include "utils.c"
#include "init.c"
#include "print.c"

#ifdef SYS_MAC
/* To compile with THINK C 4.0, place the files dawg.h grope.h,
 pack.c and utils.c in a folder.  Create a project that contains
 pack.c and the libraries unix and ANSI.
 */
#include <unix.h>
#include <stdlib.h>
#include <console.h>
/* Assume a 1Mb mac for the moment. Someday I'll add dynamic RAM sizing */
#define SMALL_MEMORY
#endif

#define TRUE (0==0)
#define FALSE (0!=0)
#define MAX_WORD_LENGTH 32

/* These two magic numbers alter a very hacky heuristic employed in
 the packing algorithm.  Tweaking them judiciously ought to speed
 it up significantly (at the expense of a slightly sparser packing */
#define DENSE_LOWER 100
#define DENSE_UPPER 200

/*###########################################################################*/
INDEX ptrie_size = 0;
static NODE PCCRAP *ptrie;
#ifdef RCHECK
/* can't use the standard range_check macro because these are slightly
 non-standard. */
#define PTRIE(x) ptrie[RANGECHECK((x), ptrie_size)]
#define DATA(x) (((x) >> 12) == 0xf2f1 ? toosmall((x), 0, __LINE__) : (x))
#else
/* so supply an explicit base case */
#define PTRIE(x) ptrie[x]
#define DATA(x) (x)
#endif
static char PCCRAP *trie_at;  /* save some time by caching this info --
                               previously it was a function called on each test */
static INDEX freenode, lowest_base = 1, highest_base = -1;
static int debug = FALSE;

#include "dawg.h"

#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

int compatible(NODE *node, INDEX i) /* Can a node be overlaid here? */
{
   int c;
   for (c = 0; c < MAX_CHARS; c++) {
      if ((node[c]&M_FREE) == 0) { /* Something to slot in... */
         if ((PTRIE(i+c) & M_FREE) == 0) return(FALSE); /* but no slot for it */
      }
   }
   return(TRUE);
}

INDEX
#ifdef PROTOTYPES
find_slot(NODE *node)
#else
find_slot(node)
NODE *node;
#endif
{               /* Try each position until we can overlay this node */
   INDEX i;
   for (i = lowest_base; i < freenode; i++) {
      if ((!trie_at[i]) && (compatible(node, i))) {
         /* nothing here already */
         /* and this one will fit */
         return(i);
      }
   }
   fprintf(stderr, "Should never fail to find a slot!\n");
   /* because the output array is larger than the input... */
   exit(5);
   /* NOT REACHED */
   return(0);
}

static int changes;

INDEX
#ifdef PROTOTYPES
pack(NODE *node)
#else
pack(node)
NODE *node;
#endif
{
   int c;
   INDEX slot;
   NODE value;
   
   slot = find_slot(node);  /* slot is also returned as the result,
                             to be used in relocation */
   /* Place node at slot */
   changes = 0;
   for (c = 0; c < MAX_CHARS; c++) {
      value = node[c];
      if ((value&M_FREE) == 0) { /* Something to fit? */
         if (((value>>V_LETTER)&M_LETTER) == (INDEX)c+BASE_CHAR) {
            /* Just a consistency check - could safely be removed */
            PTRIE(slot+c) = DATA(value);
            changes++;
         }
      }
   }
   /* The hack heuristics below keep a N^2 operation down to linear time! */
   if ((slot == lowest_base) || (slot >= lowest_base+DENSE_LOWER)) {
      /* Heuristic is: we increase the initial search position if the
       array is packed solid up to this point or we're finding it *very*
       hard to find suitable slots */
      int found = FALSE;
      for (;;) {
         INDEX c;
         while (trie_at[lowest_base]) lowest_base++;
         for (c = lowest_base; c < lowest_base+MAX_CHARS; c++) {
            if ((PTRIE(c)&M_FREE) != 0) {found = TRUE; break;}
         }
         if (found && (slot < lowest_base+DENSE_UPPER)) break;
         /* ^ Skip hard slots to fill */
         lowest_base++; /* although nothing is based here, the next N slots
                         are filled with data from the last N tries. */
         
         /* Actually I'm not sure if 256 sequential trees each with the
          same element used would actually block the next 256 slots
          without a trie_at[] flag being set for them.  However it
          does no harm to believe this... I must formally check this
          someday once all the other stuff is in order. */
      }
   }
   
   if (slot > highest_base) highest_base = slot;
   /* This is info for when we try to overlap input & output
    arrays, -- with the output sitting some large number of
    bytes lower down than the input. */
      trie_at[slot] = TRUE;
      return(slot);
}
/*###########################################################################*/

static NODE PCCRAP *dawg;
static INDEX PCCRAP *new_loc;
static INDEX nedges;

NODE this_node[MAX_CHARS];

INDEX take_node(INDEX ptr)
{
   NODE data;
   INDEX edge;
   int let;
   int endsword;
   int endsnode;
   char ch;
   int changes = 0;
   for (let = 0; let < MAX_CHARS; let++) this_node[let] = M_FREE;
      for (;;) {
         if ( let >= MAX_CHARS )
            return(0);

         data = dawg[ptr++];
         if (data == 0) {
            return(-1);
         } else {
            endsword = ((data & M_END_OF_WORD) != 0);
            endsnode = ((data & M_END_OF_NODE) != 0);
            edge = data & M_NODE_POINTER;
            let = (int) ((data >> V_LETTER) & M_LETTER);
            ch = let + BASE_CHAR;
            
            this_node[let] = edge & M_NODE_POINTER;
            if (endsword) this_node[let] |= M_END_OF_WORD;
               this_node[let] |= (NODE)ch<<V_LETTER;
               
               changes++;
            if (endsnode) break;
         }
      }
   if (changes != 0) {
      return(ptr);
   } else {
      fprintf(stderr, "Fatal error\n");
      return(0);
   }
}

NODE
#ifdef PROTOTYPES
redirect_node(NODE ptr)
#else
redirect_node(ptr)
NODE ptr;
#endif
{
   NODE data;
   INDEX edge;
   int endsword;
   char ch;
   data = DATA(PTRIE(ptr));
   
   endsword = ((data & M_END_OF_WORD) != 0);
   edge = data & M_NODE_POINTER;
   ch = (int) ((data >> V_LETTER) & M_LETTER);
   
   /*edge = dawg[edge] & M_NODE_POINTER;*/
   edge = new_loc[edge];
   
   ptr = edge;
   ptr |= (NODE)ch<<V_LETTER;
   if (endsword) ptr |= M_END_OF_WORD;
      
      return(ptr);
}

int dawg_init(char *filename, NODE PCCRAP **dawgp, INDEX *nedges);
void dawg_print(NODE PCCRAP *dawg, INDEX node);
void putword(long w, FILE *fp);

int dawg_converter2(char* inFilename, char* outFileName)
{
   INDEX dawgptr = 1, trieptr, newdawgptr, i, nodes = 0;
   FILE *triefile;
   
#ifdef SYS_MAC
   argc = ccommand(&argv);
#endif
   
   if (!dawg_init(inFilename, &dawg, &nedges)) exit(EXIT_ERROR);
      if (debug) dawg_print(dawg, (INDEX)ROOT_NODE); /* assume small test file! */
         
         freenode = ((nedges*16)/15)+(4*MAX_CHARS);
      /* Minimal slop for pathological packing? */
         ptrie_size = freenode;
         ptrie = MALLOC((SIZE_T)freenode, sizeof(NODE));
         if (ptrie == NULL) {
            fprintf(stderr, "Cannot claim %ld bytes for ptrie[]\n",
                    sizeof(NODE)*freenode);
            exit(EXIT_ERROR);
         }
   new_loc = MALLOC((SIZE_T)freenode, sizeof(NODE));
   if (new_loc == NULL) {
      fprintf(stderr, "Cannot claim %ld bytes for new_loc[]\n",
              sizeof(NODE)*freenode);
      exit(EXIT_ERROR);
   }
   trie_at = (char PCCRAP *)MALLOC((SIZE_T)freenode, sizeof(char));
   if (trie_at == NULL) {
      fprintf(stderr, "Cannot claim %ld bytes for trie_at[]\n", freenode);
      exit(EXIT_ERROR);
   }
   for (i = 0; i < freenode; i++) {
      ptrie[i] = M_FREE; new_loc[i] = 0; trie_at[i] = FALSE;
   }
   
   dawg[0] = 0; /* 1st entry is never looked at, and maps to itself */
   
   dawgptr = 1;
   
   /* Relocate initial node at 1 seperately */
   
   newdawgptr = take_node(dawgptr /* 1 */);
   trieptr = pack(this_node);
   /*dawg[dawgptr] = trieptr;*/
   /* What the hell does this do??? I've forgotten!!! - oh yes, this
    was relocating in situ, without new_loc... */
   new_loc[dawgptr] = trieptr;
   dawgptr = MAX_CHARS+1;
   
   {INDEX maxdiff = 0, diff;
      for (;;) {
         if (highest_base > dawgptr) {
            diff = highest_base - dawgptr;
            if (diff > maxdiff) maxdiff = diff;
               }
         newdawgptr = take_node(dawgptr);
         if (newdawgptr == -1) {
            dawgptr++;
            continue;
         }
         trieptr = pack(this_node);
         /*dawg[dawgptr] = trieptr;*/
         new_loc[dawgptr] = trieptr;
         dawgptr = newdawgptr;
         if (dawgptr > nedges) {
            break;  /* AHA!!! I was doing this in the
                     wrong order & lost last entry! *AND* had '>=' for '>' */
         }
         nodes++;
         if ((nodes MOD 1000) == 0) fprintf(stderr, "%ld nodes\n", nodes);
            }
      if (debug) fprintf(stderr, "wavefront gets up to %ld\n", maxdiff);
         }
   if (debug) fprintf(stderr, "All packed - used %ld nodes\n", highest_base);
      for (trieptr = 1; trieptr < freenode; trieptr++) {
         /*
          extract edge from ptrie[trieptr],
          look it up via dawg[edge], slot it back in
          (while preserving other bits)
          */
         PTRIE(trieptr) = redirect_node(trieptr);
      }
   /* Finally, remember to bump up highest_base in case last node is only
    one edge and 25 others are missing! */
   if (debug) fprintf(stderr, "Redirected...\n");
      
      triefile = fopen(outFileName, WRITE_BIN);
      if (triefile == NULL) {
         fprintf(stderr, "Cannot write to packed trie file\n");
         exit(1);
      }
   if (debug) fprintf(stderr, "File opened...\n");
      
      ptrie[0] = highest_base+MAX_CHARS-1;/* File size in words
                                           (-1 because doesn't include itself)  */
      if (debug) fprintf(stderr, "Dumping... (0..%ld)\n", highest_base+MAX_CHARS-1);
         for (i = 0; i < highest_base+MAX_CHARS; i++) {/* dump packed DAG */
            NODE n;
            n = DATA(PTRIE(i));
            putword(n, triefile);
            if (ferror(triefile)) {
               fprintf(stderr, "*** TROUBLE: Writing DAG -- disk full?\n");
               fclose(triefile);
               exit(1);
            }
         }
   if (debug) fprintf(stderr, "Dumped...\n");
      fclose(triefile);
      if (debug) fprintf(stderr, "Done.\n");
         }


@implementation DDConverter

-(void)dealloc
{
}

-(void)run
{
//   dawg_converter( "/Users/MacServer/tmp/dawg/Dict2Dawg/sowpods.txt" );
   dawg_converter2( "/Users/vgor/sowpods1.bin.dwg", "/Users/vgor/sowpods2.bin" );

   //   NSString* dict_path_ = @"/Users/MacServer/tmp/dawg/Dict2Dawg/dawg.bin";
//
//   Dict* dict_ = new Dict();
//
//   bool res_ = dict_->load( [ dict_path_ cStringUsingEncoding: NSUTF8StringEncoding ] );
//
//   NSLog( @"dict_->load: %d", res_ );
}

+(void)run
{
   static id instance_ = nil;
   if ( !instance_ )
   {
      instance_ = [ self new ];
   }
   [ instance_ run ];
}

@end

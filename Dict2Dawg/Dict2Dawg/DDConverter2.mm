//
//  DDConverter2.m
//  Dict2Dawg
//
//  Created by MaсServer on 10.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DDConverter2.h"

#import "Dict.h"

/* The first three #define's are to repair mangling by BITNET mailers */
#define EOR ^
/* This should be Caret (hat, up arrow) -- C Ex-or */
#define MOD %
/* This should be Percent -- C Modulus             */
#define NOT ~
/* This should be Tilde (twiddle) -- C unary Not   */
#include "copyr.h"
/*****************************************************************************/
/*                                                                           */
/*      FILE : DAWG.C                                                        */
/*                                                                           */
/*      Convert an alphabetically-ordered dictionary file in text format     */
/*      (one word per line) into a Directed Acyclic Word Graph. The command  */
/*      syntax is                                                            */
/*                                                                           */
/*              DAWG <text file (inc .ext)> <output file (no ext)>           */
/*                                                                           */
/*      The first 4 bytes of the output file form a 24-bit number containing */
/*      the number of edges in the dawg. The rest of the file contains the   */
/*      dawg itself (see "The World's Fastest Scrabble Program" by Appel     */
/*      and Jacobson for a description of a dawg).                           */
/*                                                                           */
/*****************************************************************************/

#include "grope.h"
#ifndef grope_h
/* If you don't have grope.h, create an empty one.
 These will do for a basic system: */
#undef KNOWS_VOID
#undef STDLIBS
#undef PROTOTYPES
#define SYS_ANY 1
#define COMPILER_ANY 1
#define SMALL_MEMORY 1
/*  To be defined if you have to generate
 the data structure in bits. This will
 certainly be true for any non-trivial
 dictionary on MSDOS, or most home
 micros with 1Mb Ram or under. */
#endif
/* Portability notes:
 
 0) KISS! Keep It Simple, Stupid!
 
 1) No typedef's
 2) No bitfields
 3) No structs
 4) No #if defined()
 5) No complex #if's
 6) No procedure variables
 7) Don't trust tolower() as some libs don't range check
 8) Stay character-set independent (EBCDIC should work?)
 9) Assume sizeof(long) >= 32 bits, but sizeof(int) just >= 16
 10) Note use of ABS in preference to unsigned longs.
 11) Assume 8-bit char set
 12) Don't use k&r reserved words for variables, even if not
 in ANSI.  Such as 'entry'.
 13) Unix people; no sys/ or machine/ files please unless under a
 suitable #ifdef, and generic code supplied for everyone else...
 14) this is byte-sex independant at the moment. KEEP IT THAT WAY!
 Don't assume dawgs are stored in a fixed form, such as so-called
 'net-order'.
 15) Since C doesn't range-check arrays, we'll do it. If possible,
 leave the running systems with range checking on if you can
 afford it!
 16) No nested include files.
 17) Don't pull in any include files twice. (*Kills* the Atari!)
 18) Don't use 'register' -- trust the compiler; the compiler is your friend.
 */
/*#define RCHECK 1*/      /* We want range-checking of array accesses */

#include <stdio.h>

#ifdef LIB_STRINGS
#include <strings.h>    /* Some unixes, Mac? */
#else
#include <string.h>
#endif

#ifdef SYS_MAC
/* To compile with THINK C 4.0, place the files dawg.h grope.h,
 dawg.c and utils.c in a folder.  Create a project that contains
 dawg.c and the libraries unix and ANSI.
 */
#include <unix.h>
#include <stdlib.h>
#include <console.h>
/* Assume a 1Mb mac for the moment. Someday I'll add dynamic RAM sizing */
#define SMALL_MEMORY 1
#endif

#include "dawg.h"   /* main system constants */

#include "utils.c"  /* utils.c pulls in header file for malloc/free & exit */

#define ABS(x) ((x) < 0 ? -(x) : (x))

/**
 *  The following constant, HASH_TABLE_SIZE, can be changed according to
 *  dictionary size.  The two values shown will be fine for both large
 *  and small systems.  It MUST be prime.
 **/

#ifdef SMALL_MEMORY
#define HASH_TABLE_SIZE 30011

#ifdef SYS_MAC
/* boy, you guys must be *really* tight on space...
 are you sure you can handle a reasonable size of dictionary with
 such a small table? Bump this back up as soon as you get everything
 else working... 
 (I was given this info by a Mac site while they were first porting
 this stuff; maybe now it works on macs we can put the buffer size
 back up to something reasonable)
 */
#undef HASH_TABLE_SIZE
#define HASH_TABLE_SIZE 17389
#endif

#else
/* pick one about 20% larger than needed */
#define HASH_TABLE_SIZE 240007

/* Suitable prime numbers if you want to tune it:
 30011
 150001  <-- probably a good compromise. OK for dicts to about 1Mb text
 200003
 220009
 240007
 
 If you try any others, for goodness sake CHECK THAT THEY ARE PRIME!!!
 
 */
#endif
#define MAX_EDGES (HASH_TABLE_SIZE-1)

static FILE *fpin, *fpout;     /* Input/output files */
static char current_word[(MAX_LINE+1)];  /* The last word read from fpin */
static int first_diff, save_first_diff;
/* The position of the first letter at which */
/* current_word differs from the previous    */
/* word read                                 */
static NODE PCCRAP *hash_table;
static int first_time = TRUE;
static int this_char = '?', lastch;
static NODE PCCRAP *dawg;

static int FILE_ENDED = FALSE;  /* I'm having real problems getting
                                 merged dawgs to work on the PC; this is yet another filthy hack. Sorry. */

static INDEX nwords, nnodes, total_edges;

#ifdef SMALL_MEMORY
#define MAX_SUBDAWG 30000 /* Big enough for largest dict,
even on small systems */
static NODE PCCRAP *merge;

static INDEX dawgsize[256];
static INDEX dawgstart[256];
static INDEX dawgentry[256];

static int nextslot;  /* Dawgs are packed in sequentially - not in their
                       'proper' indexed position */
#endif
/*
 Shorthand macros for array accesses with checking
 If RCHECK isn't defined, these don't contribute any overhead. I suggest
 leaving RCHECK on except for production code.
 */

#define EDGE_LIST(idx) \
edge_list[RANGECHECK(idx, MAX_CHARS)]
#define CURRENT_WORD(idx) \
current_word[RANGECHECK(idx, MAX_LINE+1)]
#define DAWG(idx) \
dawg[RANGECHECK(idx, MAX_EDGES)]
#define HASH_TABLE(idx) \
hash_table[RANGECHECK(idx, HASH_TABLE_SIZE)]

/*
 Forward references
 */

#ifdef PROTOTYPES
static INDEX build_node(int depth);
static INDEX add_node(NODE  *edge_list, INDEX nedges);
static void read_next_word(VOID);
static INDEX compute_hashcode(NODE *edge_list, INDEX nedges);
static void report_size(VOID);
#else
static INDEX build_node();
static INDEX add_node();
static void read_next_word();
static INDEX compute_hashcode();
static void report_size();
#endif

#ifdef SMALL_MEMORY

#ifdef PROTOTYPES
static void merge_dawg (char *filename);
#else
static void merge_dawg ();
#endif

#endif

/**
 *       main
 *
 *       Program entry point
 **/

long words; /* dirty communication variable -- the multi-pass stuff
             was hacked in at the last minute. */

int dawg_converter( char* inFilename, char* outFileName )
{
   INDEX i;
   char fname[128];
   
#ifdef SYS_MAC
   argc = ccommand(&argv);
#endif
   
//   if (argc != 3) {
//      fprintf(stderr,
//              "usage: dawg dictfile.ext dawgfile\n");
//      exit(EXIT_ERROR);
//   }
   
   /**
    *  Allocate the memory for the dawg
    **/
   
   if ((dawg = MALLOC(MAX_EDGES, sizeof(NODE PCCRAP *))) == NULL) {
      fprintf(stderr, "Can\'t allocate dictionary memory\n");
#ifndef SMALL_MEMORY
      fprintf(stderr, "-- try recompiling with -DSMALL_MEMORY\n");
#endif
      exit(EXIT_ERROR);
   }
   for (i = 0; i < (INDEX)MAX_EDGES; i++) dawg[i] = 0L;
   /**
    *  Allocate the hash table.
    *  Fill it with zeroes later just before use.  Don't trust calloc etc.
    *  - not portable enough.  Anyway, in the multi-pass version we don't
    *  want to continually free/claim...
    **/
      
      if ((hash_table =
           MALLOC((HASH_TABLE_SIZE+1), sizeof(NODE))) == NULL) {
         fprintf(stderr, "Can\'t allocate memory for hash table\n");
         exit(EXIT_ERROR);
      }
   /**
    *  Open the input/output files
    **/
   
   fpin = fopen(inFilename, READ_TEXT);
   if (fpin == NULL) {
      fprintf(stderr, "Can\'t open text file \"%s\"\n", inFilename);
      /* Could print out error string but it's not portable... */
      exit(EXIT_ERROR);
   }
   
   /**
    *  Read the first word from the dictionary
    **/
   
   first_time = TRUE;
   nwords = 0;
   current_word[0] = 0;
   read_next_word();
   lastch = *current_word;
   /**
    *  Initialise the counters, taking account of the root node (which is
    *  a special case)
    **/
   
   nnodes = 1; total_edges = MAX_CHARS;
   
   /**
    *  Build the dawg and report the outcome
    **/
   
   /* Now, in the dim & distant past, this code supported the concept
    of a restricted character set - ie a..z & A..Z were packed into 6 bits;
    this caused awful problems in the loop below, where we had to try to
    keep the loop-control variable and the character code in synch; nowadays
    chars are 8 bits or else, so I'm starting to tidy up the places
    where these hacks were necessary... */
   
#ifdef SMALL_MEMORY
   for (this_char = 0; this_char < MAX_CHARS; this_char++) {
      if (FILE_ENDED) break; /* Don't waste time in this loop... */
#endif
      /* Explicitly initialise hash table to all zeros */
      {INDEX a; for (a = 0; a <= HASH_TABLE_SIZE; a++) hash_table[a] = 0;}
      words = 0;
      (void) build_node(0);
#ifdef SMALL_MEMORY
#ifdef DEBUG
      fprintf(stderr,
              "Char %d done. %ld Words, %ld Nodes\n", *current_word, words, total_edges);
#endif
      if (total_edges /* words */ == 0) continue;
#endif
      
      /**
       *  Save the dawg to file
       **/
#ifdef SMALL_MEMORY
      sprintf(fname, "%s%c%d", outFileName, EXT_CHAR, lastch);
#else
      sprintf(fname, "%s%cdwg", outFileName, EXT_CHAR);
#endif
      fpout = fopen(fname, WRITE_BIN);
      if (fpout == NULL) {
         fprintf(stderr, "Can\'t open output file \"%s\"\n", fname);
         exit(EXIT_ERROR);
      }
#ifdef DEBUG
      fprintf(stderr, "Writing to %s\n", fname);
#endif
      
      *dawg = total_edges;
      total_edges = sizeof(NODE) * (total_edges + 1); /* Convert to byte count */
      
      {
         long cnt;
         if ((cnt = putwords(dawg, (long)total_edges, fpout)) != total_edges) {
            fprintf(stderr, "%ld bytes written instead of %ld\n.", cnt, total_edges);
            exit(EXIT_ERROR);
         }
      }
      fclose(fpout);
      
      /**
       *  Read the first word from the dictionary
       **/
      
      first_diff = save_first_diff;
      first_time = FALSE;
      nwords = 0;
      /**
       *  Initialise the counters, taking account of the root node (which is
       *  a special case)
       **/
      
      nnodes = 1; total_edges = MAX_CHARS;
      
      lastch = *current_word;
      /**
       *  Build the dawg and report the outcome
       **/
      
#ifdef SMALL_MEMORY
   }
#endif
   fclose(fpin);
   fprintf(stderr, "Dawg generated\n");
#ifdef SMALL_MEMORY
   merge_dawg(argv[2]);
#endif
   exit(EXIT_OK);
}

/**
 *       BUILD_NODE
 *
 *       Recursively build the next node and all its sub-nodes
 **/

static INDEX build_node(int depth)
{
   INDEX nedges = 0;
   INDEX i;
   NODE *edge_list;
   
   edge_list = NULL;
   if (CURRENT_WORD(depth) == 0) {
      /**
       *  End of word reached. If the next word isn't a continuation of the
       *  current one, then we've reached the bottom of the recursion tree.
       **/
      
      read_next_word();
      if (first_diff < depth) return(0);
   }
   
   edge_list = (NODE *)malloc(MAX_CHARS*sizeof(NODE));
   /* Note this is a 'near' array */
   if (edge_list == NULL) {
      fprintf(stderr, "Stack full (depth %d)\n", depth);
      exit(EXIT_ERROR);
   }
   for (i = 0; i < MAX_CHARS; i++) EDGE_LIST(i) = 0L;
      
   /**
    *  Loop through all the sub-nodes until a word is read which can't
    *  be reached via this node
    **/
      
      do
      {
         /* Construct the edge. Letter.... */
         EDGE_LIST(nedges) = (NODE) (((NODE)CURRENT_WORD(depth)))
         << (NODE)V_LETTER;
         /* ....end-of-word flag.... */
         if (CURRENT_WORD(depth+1L) == 0) EDGE_LIST(nedges) |= M_END_OF_WORD;
         /* ....and node pointer. */
         EDGE_LIST(nedges) |= build_node(depth+1); nedges++;
         /* (don't ++ in a macro) */
      } while (first_diff == depth);
   
   if (first_diff > depth) {
      fprintf(stderr, "Internal error -- first_diff = %d, depth = %d\n",
              first_diff, depth);
      exit(EXIT_ERROR);
   }
   
   EDGE_LIST(nedges-1) |= M_END_OF_NODE;
   /* Flag the last edge in the node */
   
   /**
    *  Add the node to the dawg
    **/
   
   if (depth) {
      NODE result = add_node(edge_list, nedges);
      free(edge_list);
      return(result);
   }
   
   /**
    *  depth is zero, so the root node (as a special case) goes at the start
    **/
   
   edge_list[MAX_CHARS-1] |= M_END_OF_NODE;      /* For backward searches */
   for (i = 0; i < MAX_CHARS; i++)
   {
      dawg[i+1] = edge_list[i];
   }
   free(edge_list);
   return(0);
}

/**
 *       ADD_NODE
 *
 *       Add a node to the dawg if it isn't already there. A hash table is
 *       used to speed up the search for an identical node.
 **/

static INDEX
#ifdef PROTOTYPES
add_node(NODE *edge_list, INDEX nedges)
#else
add_node(edge_list, nedges)
NODE *edge_list;
INDEX nedges;
#endif
{
   NODE hash_entry;
   INDEX inc;
   INDEX a, first_a;
   INDEX i;
   
   /**
    *  Look for an identical node. A quadratic probing algorithm is used
    *  to traverse the hash table.
    **/
   
   first_a = compute_hashcode(edge_list, nedges);
   first_a = ABS(first_a) MOD HASH_TABLE_SIZE;
   a = first_a;
   inc = 9;
   
   for (;;)
   {
      hash_entry = HASH_TABLE(a) & M_NODE_POINTER;
      
      if (hash_entry == 0) break;   /* Node not found, so add it to the dawg */
      
      for (i = 0; i < nedges; i++)
         if (DAWG((hash_entry+i) MOD HASH_TABLE_SIZE) != EDGE_LIST(i)) break;
      
      /* On the 1.6M dictionary, this gave a rangecheck with < 0. Now fixed
       I think - it was a problem with MOD giving unexpected results. */
      
      if (i == nedges) {
         return(hash_entry);        /* Node found */
      }
      /**
       *  Node not found here. Look in the next spot
       **/
      
      a += inc;
      inc += 8;
      if (a >= HASH_TABLE_SIZE) a -= HASH_TABLE_SIZE;
      if (inc >= HASH_TABLE_SIZE) inc -= HASH_TABLE_SIZE;
      if (a == first_a) {
         fprintf(stderr, "Hash table full\n");
         exit(EXIT_ERROR);
      }
   }
   
   /**
    *  Add the node to the dawg
    **/
   
   if (total_edges + nedges >= MAX_EDGES) {
      fprintf(stderr,
              "Error -- dictionary full - total edges = %ld\n", total_edges);
      exit(EXIT_ERROR);
   }
   
   HASH_TABLE(a) |= total_edges + 1;
   nnodes++;
   for (i = 0; i < nedges; i++) {
      DAWG((total_edges + 1 + i) MOD HASH_TABLE_SIZE) = EDGE_LIST(i);
   }
   total_edges += nedges;
   return(total_edges - nedges + 1);
}

/**
 *       READ_NEXT_WORD
 *
 *       Read the next word from the input file, setting first_diff accordingly
 **/

static void read_next_word(VOID)
{
   /* This stuff imposes the limitation of not allowing '\0' in a word;
    not yet a problem but the dawg structure itself could probably cope
    if the feature were wanted. (Maybe with a little teweaking)       */
   char linebuff[(MAX_LINE+1)];
   int length;
   for (;;)
   {
      int next = 0, c;
      for (;;) {
         c = fgetc(fpin);
         if (FILE_ENDED || c == EOF || ferror(fpin) || feof(fpin)) {
            /* for some reason, we always get a blank line at the end of files */
            current_word[0] = 0;
            first_diff = -1;
            linebuff[next] = '\0';
            FILE_ENDED = TRUE;
            return;
         }
         c &= 255;
         if (next == 0 && c == '\n') continue; /* skip blank lines... */
         linebuff[next++] = c;
         if (c == '\n') break;
      }
      linebuff[next] = '\0';
      
      words++;
      
      length = strlen(linebuff);
      
      if (linebuff[length-1] == '\n') linebuff[length-1] = '\0';
      if (linebuff[length] == '\n') linebuff[length] = '\0';
      
      if (length < 2 || length > MAX_LINE-1)
      {
         fprintf(stderr, "\n%s - invalid length\n", linebuff);
         continue;    /* Previously exit()ed, but now ignore so that
                       test sites without my pddict can use /usr/dict/words */
      }
      break;
   }
   for (length = 0; current_word[length] == linebuff[length]; length++) {
      /* Get common part of string to check order */
   }
   if (current_word[length] > linebuff[length]) {
      fprintf(stderr, "Error -- %s (word out of sequence)\n", linebuff);
      exit(EXIT_ERROR);
   }
   first_diff = length;
   
   nwords++;
   strcpy(current_word, linebuff);
   
   if ((nwords > 1) && (!(nwords & 0x3FF))) report_size();
#ifdef SMALL_MEMORY
   if (current_word[0] != lastch) {
      save_first_diff = first_diff;
      first_diff = -1;
      report_size();
   }
#else
   this_char = current_word[0]; /* for diagnostics... */
#endif
}
/**
 *       COMPUTE_HASHCODE
 *
 *       Compute the hash code for a node
 **/

static INDEX
#ifdef PROTOTYPES
compute_hashcode(NODE *edge_list, INDEX nedges)
#else
compute_hashcode(edge_list, nedges)
NODE *edge_list;
INDEX nedges;
#endif
{
   INDEX i;
   INDEX res = 0L;
   
   for (i = 0; i < nedges; i++)
      res = ((res << 1) | (res >> 31)) EOR EDGE_LIST(i);
      return(res);
}

/**
 *       REPORT_SIZE
 *
 *       Report the current size etc
 **/

static void
#ifdef PROTOTYPES
report_size(VOID)
#else
report_size()
#endif
{
   
   if (first_time)
   {
      fprintf(stderr, "      Words    Nodes    Edges    Bytes    BPW\n");
      fprintf(stderr, "      -----    -----    -----    -----    ---\n");
      first_time = FALSE;
   }
   if (*current_word) fprintf(stderr, "%c:", *current_word);
   else fprintf(stderr, "Total:");
   
   /* THE FOLLOWING IS RATHER GRATUITOUS USE OF FLOATING POINT - REMOVE
    IT AND REPLACE WITH INTEGER ARITHMETIC * 100 */
   
   /* (hey - I already did this in the copy I sent to Richard; so how
    come its missing? Oh no, not again: I've got out of synch and
    used an old copy, haven't I? :-(   ) */ 
   
   fprintf(stderr, "  %7ld  %7ld  %7ld  %7ld  %5.2f\n",
           nwords, nnodes, total_edges, sizeof(NODE PCCRAP *)*(total_edges+1),
           (float)(sizeof(NODE PCCRAP *)*(total_edges+1))/(float)nwords);
}

#ifdef SMALL_MEMORY
static void merge_dawg (char *filename)
{
   FILE *fp, *outfile;
   NODE data, edge;
   INDEX nedges, nextfree, i, dentry;
   INDEX count, lastnode;
   int dictch, padding;
   char fname[128];
   
   nedges = (INDEX)MAX_SUBDAWG;
   if ((merge = MALLOC((SIZE_T)nedges, sizeof(INDEX))) == 0) {
      fprintf(stderr, "Memory allocation error -- %ld wanted\n",
              nedges*sizeof(INDEX));
      exit(EXIT_ERROR);
   }
   
   nextfree = MAX_CHARS; /* 0 is special, 1..26 are root nodes for a..z */
   nextslot = 0;
   for (dictch = 0; dictch < MAX_CHARS; dictch++) {
      /***
       *   Open the file and find out the size of the dawg
       ***/
      sprintf(fname, "%s%c%d", filename, EXT_CHAR, dictch);
      if ((fp = fopen(fname, READ_BIN)) == NULL) {
         continue;
      }
      nedges = getword(fp);
      dawgstart[nextslot] = nextfree;
      dawgsize[nextslot] = nedges-MAX_CHARS;
      
      /* the first entry is (erroneously) the pointer to the chunk */
      dentry = getword(fp);
      dawgentry[nextslot] = dentry - MAX_CHARS + nextfree;
      
      nextfree += nedges - MAX_CHARS;
      nextslot++;
      
      fclose(fp);
   }
   
   /* Now output total edges, and starts[a..z] */
   /* Then set nextfree to start of each block  */
   sprintf(fname, "%s%cdwg", filename, EXT_CHAR);
   outfile = fopen(fname, WRITE_BIN);
   if (outfile == NULL) {
      fprintf(stderr, "Cannot open output dawg file %s\n", fname);
      exit(EXIT_ERROR);
   }
   putword(nextfree, outfile);
   nextfree = 1; nextslot = 0; padding = 0;
   lastnode = MAX_CHARS-1;
   for (;;) {
      if (dawgentry[lastnode] != 0) break; /* Leave with 'lastnode' set */
      lastnode -= 1;
   }
   for (dictch = 0; dictch < MAX_CHARS; dictch++) {
      NODE edge = dawgentry[nextslot];
      if (edge == 0) {
         padding++;
         continue;
      }
      if (dictch == lastnode) {
         edge |= M_END_OF_NODE;
      } else {
         edge &= (NOT M_END_OF_NODE);
      }
      putword(edge, outfile);
      nextfree++; nextslot++;
   }
   nextfree += padding;
   while (padding > 0) {
      putword(0L, outfile); padding -= 1;
   }
   /* nextslot = 0; ???? This one not used? */
   for (dictch = 0; dictch < MAX_CHARS; dictch++) {
      sprintf(fname, "%s%c%d", filename, EXT_CHAR, dictch);
      if ((fp = fopen(fname, READ_BIN)) == NULL) {
         continue;
      }
      
      nedges = getword(fp);
      
      for (i = 0; i < MAX_CHARS; i++) {
         (void) getword(fp);
         /* Skip root pointers */
      }
      
      nedges -= MAX_CHARS;
      count = getwords(&merge[1], (long)(nedges*sizeof(NODE)), fp);
      if (count != nedges*sizeof(NODE)) {
         fprintf(stderr, "Dictionary read error - %ld wanted - %ld got\n",
                 nedges*sizeof(NODE), count);
         exit(EXIT_ERROR);
      }
      fclose(fp);
      
      DELETE(fname);    /* On floppy systems, we can almost get away with
                         little more space than the final files would take! */
      
      /* relocate all nodes */
      for (i = 1; i <= nedges; i++) {
         data = merge[i];
         edge = data & M_NODE_POINTER;
         if (edge > MAX_CHARS) {
            data &= (NOT M_NODE_POINTER);
            data |= edge - MAX_CHARS - 1 + nextfree;
            merge[i] = data;
         }
         putword(merge[i], outfile);
      }
      nextfree += nedges;
      /*  nextslot++;   this one not used??? */
   }
   fclose(outfile);
   FREE(merge);
}
#endif


@implementation DDConverter2

-(void)run
{
//   dawg_converter( "/Users/vgor/Player.txt", "/Users/vgor/sowpods1.bin" );
   Dict* dict_ = new Dict();

   bool res_ = dict_->load( "/Users/vgor/sowpods1.bin.dwg" );

   NSLog( @"dict_->load: %d", res_ );

//   NSLog( @"contains: %d", dict_->contains( "abacterial" ) );
//   NSLog( @"contains: %d", dict_->contains( "RIGOROUSNESSES" ) );
//   NSLog( @"contains: %d", dict_->contains( "RIJSTAFELS" ) );
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

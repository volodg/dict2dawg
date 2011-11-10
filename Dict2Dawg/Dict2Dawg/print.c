/*

    File:    print.c
    Author:  Graham Toal
    Purpose: Print a packed trie to stderr.
    Functions exported:  dawg_print, pack_print, dawg_print_prefix
    Internal functions:  pack_pr dawg_pr dawg_pr_prefix

Description:
  Pre-order traverse of packed TRIE or DAWG.  Will be modified
  soon to take output file as parameter.  Then sometime after that
  to callback with each string at it is generated.  Meanwhile,
  people requiring custom versions of dawg-walking stuff might
  as well just copy this code and edit it to do what they want.

  The special version print_dawg_prefix takes a NODE from somewhere
  in a dict as a parameter, and prints out only those words which
  contain that node.  You have to locate the node seperately with
  'locate_prefix', and pass the prefix string in so it can be printed.

*/

#define TRUE (0==0)
#define FALSE (0!=0)

#define DAWG_MAGIC 0x01234567
#define PACK_MAGIC 0x34567890

#define TERMINAL_NODE 0
#define ROOT_NODE 1

#define V_END_OF_WORD   23
#define M_END_OF_WORD   (1L << V_END_OF_WORD)
#define V_END_OF_NODE   22                     /* Bit number of N */
#define M_END_OF_NODE   (1L << V_END_OF_NODE)   /* Can be tested for by <0 */


#define V_FREE          22             /* Overloading this bit, as
packed tries need no end-of-node */
#define M_FREE          (1L << V_FREE)

#define V_LETTER        24
#define M_LETTER        0xFF
#define M_NODE_POINTER  0x1FFFFFL     /* Bit mask for node pointer */

/* max_chars and base_chars are a hangover from the days when this
 was trying to save space, and dawgs were only able to contain
 characters in the range 'a'..'z' 'A'..'Z' (squeezed into 6 bits).
 Now that we're '8-bit clean' we no longer need these.  Later code
 in fact doesn't support the old style; but some procedures still
 subtract 'BASE_CHAR' from the character to normalize it.  Since it
 is now 0 it is a no-op... */
#define MAX_CHARS       256
#define BASE_CHAR       0

/* Enough? */
#define MAX_WORD_LEN    256

#define MAX_LINE        256

#include "dawg.h"

#include <stdio.h>

static void dawg_pr(NODE PCCRAP *dawg, INDEX node, int len)
{
  static char word[MAX_WORD_LEN];
  NODE PCCRAP *edge;

  for (edge = (NODE PCCRAP *)&dawg[node]; ; edge++) {
  long c;
    c = *edge;           /* Don't rewrite this - its avoiding a MSC bug */
    c = c >> V_LETTER;
    c = c & M_LETTER;
    word[len] = (char)c;
    if ((*edge & M_END_OF_WORD) != 0) {
      word[len+1] = '\0';
      fprintf(stdout, "%s\n", word);
    }
    c = *edge & M_NODE_POINTER;
    if ((*edge & M_NODE_POINTER) != 0)
      dawg_pr (dawg, c, len + 1);
    if ((*edge & M_END_OF_NODE) != 0) break; /* End of node */
  }
}

void
#ifdef PROTOTYPES
dawg_print(NODE PCCRAP *dawg, INDEX node)
#else
dawg_print(dawg, node)
NODE PCCRAP *dawg;
INDEX node;
#endif
{
  dawg_pr(dawg, node, 0);
}

static void
#ifdef PROTOTYPES
pack_pr(NODE PCCRAP *ptrie, INDEX i, int pos)
#else
pack_pr(ptrie, i, pos)
NODE PCCRAP *ptrie;
INDEX i;
int pos;
#endif
{
static char s[MAX_WORD_LEN+1];
int b;
INDEX p;
  for (b = BASE_CHAR; b < BASE_CHAR+MAX_CHARS; b++) {
    if (b != 0) {
      p = ptrie[i+b-BASE_CHAR];
      if (((p>>V_LETTER)&M_LETTER) == b) {
      	s[pos] = b; s[pos+1] = '\0';
        if ((p & M_END_OF_WORD) != 0) fprintf(stderr, "%s\n", s);
        if ((p &= M_NODE_POINTER) != 0) {
          pack_pr(ptrie, p, pos+1);
        }
      }
    }
  }
}


void
#ifdef PROTOTYPES
pack_print(NODE PCCRAP *ptrie, INDEX node)
#else
pack_print(ptrie, node)
NODE PCCRAP *ptrie;
INDEX node;
#endif
{
  pack_pr(ptrie, node, 0);
}


static void
#ifdef PROTOTYPES
dawg_pr_prefix(NODE PCCRAP *dawg, char *prefix, INDEX node, int len)
#else
dawg_pr_prefix(dawg, prefix, node, len)
NODE PCCRAP *dawg;
char *prefix;
INDEX node;
int len;
#endif
{
  NODE PCCRAP *edge;
  static char word[MAX_WORD_LEN];
  long c;

  for (edge = (NODE PCCRAP *)&dawg[node]; ; edge++) {
    /* Don't 'fix' - compiler bugaround for microsoft :-( */
    c = *edge; c = c >> V_LETTER; c = c & M_LETTER;
    word[len] = (char)c;
    if ((*edge & M_END_OF_WORD) != 0) {
      word[len+1] = 0;
      fprintf(stdout, "%s%s\n", prefix, word);
    }
    c = *edge & M_NODE_POINTER;
    if (c != 0) dawg_pr_prefix(dawg, prefix, c, len + 1);
    /* End of node - check repair later - I accidentally nobbled it */
    if ((*edge & M_END_OF_NODE) != 0) break;
  }
}

void
#ifdef PROTOTYPES
dawg_print_prefix(NODE PCCRAP *dawg, char *prefix, INDEX node)
#else
dawg_print_prefix(dawg, prefix, node)
NODE PCCRAP *dawg;
char *prefix;
INDEX node;
#endif
{
  dawg_pr_prefix(dawg, prefix, node, 0);
}

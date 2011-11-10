/*

    File:    init.c
    Authors: Richard Hooker, Graham Toal
    Purpose: Loading of dictionary for spelling checker.
    Functions exported:  dawg_init, pack_init
    Internal functions:  spell_init

Description:

The address of a dictionary (either a PACKed dict or a DAWG) is set up by
this procedure.  This gives us the option of connecting the dict in read-only
(or copy-on-write) virtual memory.  On non-VM machines, we simply allocate a
large buffer into which the relevant part of the dictionary is loaded.

The magic number is used to check the dict type, *and* the machine byte-sex.
If the sex is reversed, even a VM system has to load the data into writable
memory (so that it can reverse it).

*/

/*######################### INTERNAL FUNCTIONS #########################*/

#include "dawg.h"

#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

static int
spell_init(char *filename, NODE PCCRAP **dictp,
  char *DEFAULT_DICT, long magic_number, INDEX *nedges)
#define dict (*dictp)
{
   FILE *fp = NULL;
   INDEX count;

  /*  init_dict("") gets default */
  if (*filename == '\0') filename = DEFAULT_DICT;

  /* Open the file and find out the size of the dict -- which
     is stored in the first word.  Later I'll change the dict format
     to have a header, and the header will have to be skipped by
     this module. */

  if ((fp = fopen(filename, "rb")) == NULL) {
    fprintf (stderr, "Can\'t open file \"%s\"\n", filename);
    return(FALSE);
  }
  *nedges = getword(fp);
#ifdef DEBUG
fprintf(stderr, "dawg contains %8lx edges\n", *nedges);
#endif
  /* Allocate precisely enough memory for all edges + 0 at root node. */
   long size_to_malloc_ = ((*nedges)+1);
   long size_bites_ = sizeof(NODE PCCRAP *);
  if ((dict = MALLOC(size_to_malloc_, size_bites_)) == 0) {
    fprintf (stderr, "Can\'t allocate space for dictionary\n");
    return(FALSE);
  }

  dict[0] = 0; /* Root node set to 0; terminal nodes point to 0. */

  /* Load in the dictionary.  Routine 'getwords' should be efficient */
  count = getwords(&dict[1], (long)(4*(*nedges)), fp);
  if (count != 4*(*nedges)) {
    fprintf(stderr,
      "Failed to read dictionary %s - wanted %ld bytes, got %ld\n",
      filename, 4*(*nedges), count);
    return(FALSE);
  }
  fclose(fp);

  return(TRUE);
#undef dict
}

/*####################### EXPORTED FUNCTIONS #########################*/

int dawg_init(char *filename, NODE PCCRAP **dawgp, INDEX *nedges)
{
  return(spell_init(filename, dawgp, DEFAULT_DAWG, DAWG_MAGIC, nedges));
}

int
#ifdef PROTOTYPES
pack_init(char *filename, NODE PCCRAP **packp, INDEX *nedges)
#else
pack_init(filename, packp, nedges)
char *filename;
NODE PCCRAP **packp;
INDEX *nedges;
#endif
{
  return(spell_init(filename, packp, DEFAULT_PACK, PACK_MAGIC, nedges));
}


/**
*
*       DAWG.H
*
*       Header file for Directed Acyclic Word Graph access
*
*       The format of a DAWG node (8-bit arbitrary data) is:
*
*        31                24 23  22  21                                     0
*       +--------------------+---+---+--+-------------------------------------+
*       |      Letter        | W | N |??|            Node pointer             |
*       +--------------------+---+---+--+-------------------------------------+
*
*      where N flags the last edge in a node and W flags an edge as the
*      end of a word. 21 bits are used to store the node pointer, so the
*      dawg can contain up to 262143 edges. (and ?? is reserved - all code
*      generating dawgs should set this bit to 0 for now)
*
*      The root node of the dawg is at address 1 (because node 0 is reserved
*      for the node with no edges).
*
*      **** PACKED tries do other things, still to be documented!
*
**/

#ifndef KJGKGKYKUBYKUYGJKHGKGHFHJFGHJ
#define KJGKGKYKUBYKUYGJKHGKGHFHJFGHJ

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

typedef long NODE;
typedef long INDEX;

#define PCCRAP


#ifdef SYS_RISCOS
#define DEFAULT_DAWG "run:dict-dwg"
#define DEFAULT_PACK "run:dict-pck"
#else
#ifdef SYS_EMAS
#define DEFAULT_DAWG "dict#dwg"
#define DEFAULT_PACK "dict#pck"
#else
/* Unix, MessDross, etc... */
#define DEFAULT_DAWG "dict.dwg"
#define DEFAULT_PACK "dict.pck"
#endif
#endif

#endif //KJGKGKYKUBYKUYGJKHGKGHFHJFGHJ

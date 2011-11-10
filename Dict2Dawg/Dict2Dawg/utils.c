/*

    File:    utils.c
    Author:  Graham Toal
    Purpose: Portability library

Description:

   Most of what differs between operating systems is handled here.
   This module is *incredibly* hacky -- I've just been interested
   in finding the problems so far, not in making the solutions neat.

   The final release of this suite will concentrate on cleaning up
   this file!
*/



/* PENDING: Generic load dict; meanwhile should also put efficient
   msdos file loading into getwords().  See spelldawg for best coding. */

#include "dawg.h"

#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#define SIZE_T size_t
/* MSDos redefines this for huge allocation */


/* Undo any #define's here if they are inappropriate for some system */

#define EXT_CHAR '.'

#define READ_TEXT "r"
#define WRITE_BIN "wb"
#define READ_BIN "rb"


/* system configuration */

#ifdef KNOWS_VOID
#define VOID void
#else
/* As in... void fred(VOID) */
#define void int
#define VOID
#endif

#ifdef SYS_MSDOS
#ifdef COMPILER_ZORTECH
int _stack = 0x3000;
#define PCCRAP far
#else
#ifdef COMPILER_TURBOC
#define PCCRAP far
#else
#define PCCRAP huge
#endif
#endif
#else
#define PCCRAP
#endif

/* Hmph... I don't really want to do realloc too.  Just as well that
   one implmentation is buggy; saves me having to work out what to do :-) */


#ifdef SYS_MSDOS
/* Normally int... */
#undef SIZE_T
#define SIZE_T long
/* (Still to test AZTEC & LATTICE) */
/* Mallocs of > 64K (maybe even > 32K) have to come off the far/huge heap */
#ifdef COMPILER_ZORTECH
#include <dos.h>
#define MALLOC(x,s) (NODE PCCRAP *)farmalloc((x)*(s)) /* Zortech */
#define Malloc(x,s) malloc((x)*(s))
#define FREE(x) farfree(x)
#define Free(x) free(x)
#else /* else not microsoft */
#ifdef COMPILER_TURBOC
#include <alloc.h>
#define MALLOC(x,s) (NODE PCCRAP *)farmalloc((x)*(s))  /* Turbo */
#define Malloc(x,s) malloc((x)*(s))
#define FREE(x) farfree(x)
#define Free(x) free(x)
#else /* else not turbo */
#include <malloc.h>
#ifdef NEVER
#define MALLOC(x,s) (NODE PCCRAP *)my_halloc((long)(x),(size_t)(s))
 /* Microsoft, Aztec */
#define Malloc(x,s) my_malloc((x)*(s))
#define FREE(x) my_hfree((void huge *)(x))  /* For some reason MICROSOFT    */
#define Free(x) my_free((void *)x)          /* complains of a type mismatch */
                                         /* without these casts */
#endif
#define MALLOC(x,s) (NODE PCCRAP *)halloc((long)(x),(size_t)(s))
 /* Microsoft, Aztec */
#define Malloc(x,s) malloc((x)*(s))
#define FREE(x) hfree((void huge *)(x))  /* For some reason MICROSOFT    */
#define Free(x) free((void *)x)          /* complains of a type mismatch */
                                         /* without these casts */
#endif
#endif
#else /* else not SYS_MSDOS */
#ifdef STDLIBS
#include <stdlib.h>  /* for malloc, free & exit */
#define MALLOC(x,s) (NODE PCCRAP *)calloc((x),(s))
#define Malloc(x,s) calloc((x),(s))
#define FREE(x) free(x)
#define Free(x) free(x)
#else
#define MALLOC(x,s) (NODE PCCRAP *)calloc((x),(s))
#define Malloc(x,s) calloc((x),(s))
#define FREE(x) free(x)
#define Free(x) free(x)
#ifndef size_t       /* Doesn't work if size_t was typedef'd */
#define size_t int   /* And if an int isn't big enough we're in trouble! */
#endif
#ifdef PROTOTYPES
extern void *malloc(size_t bytes);
extern void exit(int rc);
#else
extern void *malloc();
extern void exit();
#endif
#endif /* not stdlibs */
#endif /* Not msdos */

#ifdef SYS_RISCOS
#undef EXT_CHAR
#define EXT_CHAR '-'
#endif

#ifdef SYS_EMAS
#undef EXT_CHAR
#define EXT_CHAR '#'
#endif

#ifdef SYS_MAC
#ifdef COMPILER_THINK
#undef WRITE_BIN
#undef READ_BIN
#define WRITE_BIN "w"
#define READ_BIN "r"
#endif
#endif

#ifdef MEMMODELS
#define SMALL_MEMORY 1
#endif

/*
                     Error handling

     At the moment we'll just go for OK / NOT OK.  Later we should
   fix all exit's to use a specific code symbol (eg EXIT_MALLOCFAIL)
   but this has to be done system by system.  Whenever a new one is
   added, a default should be set up (as 0?)
 */

/*#include <errno.h>*/        /* Only later when we want to be more precise! */
#define EXIT_OK       (0)     /* Generic success              */
#define EXIT_ERROR    (1)     /* Generaic failure             */

/* For each system, replace generic errors with system-dependant ones. */
#ifdef vms
/*
 * VMS-specific error status codes.  Approximate Ultrix equivalents.
 */
#include <ssdef.h>
#include <stsdef.h>
#undef  EXIT_OK
#define EXIT_OK     SS$_NORMAL     /* Generic success                  */
#undef  EXIT_ERROR
#define EXIT_ERROR  SS$_NORMAL     /* Don't want random error message! */
#endif

#define DELETE(filename)

#ifdef __STDC__
#undef DELETE
#define DELETE(filename) remove(filename)
#else
#ifdef unix
#undef DELETE
#define DELETE(filename) unlink(filename)
#endif
#endif

#ifdef NEVER

/* these macros caught the fact that on MICROSOFT, the parameters
   being passed in were ints -- and I hadn't been given a warning
   because I had explicitly cast the to size-t.  Hence why I've
   declared SIZE_T as long.  This is all a bit messy. Curse you IBM PCs
 */

void PCCRAP *my_halloc(long n,size_t s) {
char PCCRAP *p;
  p = halloc(n, s);
  fprintf(stderr, "halloc(%8lx*%d) -> %8lx\n", n, s, (long)p);
  return(p);
}

void *my_malloc(size_t s) {
char *p;
  p = malloc(s);
  fprintf(stderr, "malloc(%4x) -> %4x\n", s, (int)p);
  return(p);
}

void my_hfree(void PCCRAP *p) {
  fprintf(stderr, "hfree(%8lx)\n", (long)p);
  hfree(p);
}

void my_free(void *p) {
  fprintf(stderr, "free(%4x)\n", (int)p);
  free(p);
}
#endif


#ifdef RCHECK
#ifndef PROTOTYPES
long toosmall(idx, max, line)
long idx;
long max;
int line;
#else
long toosmall(long idx, long max, int line)
#endif
{
  if (line == 0) {
    fprintf(stderr,
      "RANGE CHECK: %ld should not be less than 0 (max %ld)\n", idx, max);
  } else {
    fprintf(stderr,
      "RANGE CHECK AT LINE %d: %ld should not be less than 0 (max %ld)\n",
      line, idx, max);
  }
  return(0L);
}
#ifndef PROTOTYPES
long toobig(idx, max, line)
long idx;
long max;
int line;
#else
long toobig(long idx, long max, int line)
#endif
{
  if (line == 0) {
    fprintf(stderr,
      "RANGE CHECK: %ld should not be larger than %ld\n", idx, max);
  } else {
    fprintf(stderr,
      "RANGE CHECK AT LINE %d: %ld should not be larger than %ld\n",
      line, idx, max);
  }
  return(max);
}

#ifdef KNOWS_LINE
#define TOOSMALL(idx, max) toosmall((long)idx, (long)max, __LINE__)
#define TOOBIG(idx, max) toobig((long)idx, (long)max, __LINE__)
#else
#define TOOSMALL(idx, max) toosmall((long)idx, (long)max, 0)
#define TOOBIG(idx, max) toobig((long)idx, (long)max, 0)
#endif

#define RANGECHECK(idx,max) \
  (idx < 0 ? (TOOSMALL(idx,max)) : (idx >= max ? (TOOBIG(idx,max)) : idx))
#else
#define RANGECHECK(idx,max) (idx)
#endif

long getwords(long PCCRAP *data, long count, FILE *fp)
{
#ifdef SYS_MSDOS
char PCCRAP *p; int c; long byte_count;
  p = (char PCCRAP *)(&data[0]);
  /* Somewhere I have a version which fread()s into a 16K near
     buffer, then copies it out; use that technique here - *MUCH*
     faster */
  for (byte_count = 0; byte_count < count; byte_count++) {
    c = fgetc(fp);
    if (c == -1 || ferror(fp)) {
      printf ("Dictionary read error - %ld wanted - %ld got\n",
        count, byte_count)/*, exit(0)*/;
      break;
    }
    *p++ = (c & 255);
  }
  return(count);
#else
  return((long)fread(&data[0], (size_t)1, (size_t)count, fp));
#endif
}

long putwords(long PCCRAP *data, long count, FILE *fp)
{
#ifdef SYS_MSDOS
extern int _NEAR _CDECL errno;
long i; char PCCRAP *p;
  p = (char PCCRAP *)&data[0];
  if (fp == NULL) {
    fprintf(stderr, "putwords: no file?\n");
    exit(0);
  }
  for (i = 0L; i < count; i++) {
  /* Somewhere I have a version which copies to a 16K near
     buffer, then frwrite()s it out; use that technique here - *MUCH*
     faster */
    int rc = fputc(*p++, fp);
    if (ferror(fp)) {
      fprintf(stderr, "rc = %d\n", rc);
      perror("dawg");
      fprintf (stderr, "Error writing to output file\n");
      exit(0);
    }
  }
  return(count);
#else
  return(fwrite(&data[0], (size_t)1, (size_t)count, fp));
#endif
}

static long PCCRAP *WTMP = NULL;
/* A bit hacky having this single 4 bytes in heap space, but it makes
   things a little more consistent.  it'll all go away eventually
   anyway... */

void putword(long w, FILE *fp)
{
  if (WTMP == NULL) {
    WTMP = (long PCCRAP *)MALLOC(1,sizeof(long));
  }
  *WTMP = w;
  if (putwords(WTMP, (long)sizeof(long), fp) != sizeof(long)) {
    /* (using putwords avoids confusion over bytesex) */
    fprintf(stderr, "Data write error - putword\n");
  }
}

long getword(FILE *fp)
{
  if (WTMP == NULL) {
    WTMP = (long PCCRAP *)MALLOC(1,sizeof(long));
  }
  if (getwords(WTMP, (long)sizeof(long), fp) != sizeof(long)) {
    fprintf(stderr, "Data read error - getword\n");
  }
  return(*WTMP);
}

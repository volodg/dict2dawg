#include "line_counter.h"

#include <stdio.h>
#include <stdlib.h>

/* Print error message and exit with error status. If PERR is not 0,
 display current errno status. */
static void error_print (int perr, char *fmt, va_list ap)
{
   vfprintf (stderr, fmt, ap);
   if (perr)
      perror (" ");
   else
      fprintf (stderr, "\n");
   exit (1);  
}

/* Print error message followed by errno status and exit
 with error code. */
static void perrf (char *fmt, ...)
{
   va_list ap;

   va_start (ap, fmt);
   error_print (1, fmt, ap);
   va_end (ap);
}

/* Return true if C is a valid word constituent */
static int isword (unsigned char c)
{
   return isalpha (c);
}

/* Get next word from the input stream. Return 0 on end
 of file or error condition. Return 1 otherwise. */
static int getword (FILE *fp, long long* lcount)
{
   int c;

   if (feof (fp))
      return 0;

   while ((c = getc (fp)) != EOF)
   {
      if (isword (c))
      {
         break;
      }
      if ( c == '\n' ) (*lcount)++;
   }

   for (; c != EOF; c = getc (fp))
   {
      if ( c == '\n' ) (*lcount)++;
      if (!isword (c))
         break;
   }

   return c != EOF;
}

/* Process file FILE. */
long long line_counter ( const char *file)
{
   FILE *fp = fopen (file, "r");

   if (!fp)
      perrf ("cannot open file `%s'", file);

   long long lcount = 0;
   while (getword (fp, &lcount));
   fclose (fp);

   return lcount;
}

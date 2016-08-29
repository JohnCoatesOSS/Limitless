// -*- mode: cpp; mode: fold -*-
// Description								/*{{{*/
// $Id: pkgcache.h,v 1.25 2001/07/01 22:28:24 jgg Exp $
/* ######################################################################
   
   Cache - Structure definitions for the cache file
   
   Please see doc/apt-pkg/cache.sgml for a more detailed description of 
   this format. Also be sure to keep that file up-to-date!!
   
   Clients should always use the CacheIterators classes for access to the
   cache. They provide a simple STL-like method for traversing the links
   of the datastructure.
   
   See pkgcachegen.h for information about generating cache structures.
   
   ##################################################################### */
									/*}}}*/
#ifndef PKGLIB_PKGSTRING_H
#define PKGLIB_PKGSTRING_H

#include <string>

class srkString
{
   public:
   const char *Start;
   size_t Size;

   srkString() : Start(NULL), Size(0) {}

   srkString(const char *Start, size_t Size) : Start(Start), Size(Size) {}
   srkString(const char *Start, const char *Stop) : Start(Start), Size(Stop - Start) {}
   srkString(const std::string &string) : Start(string.c_str()), Size(string.size()) {}

   bool empty() const { return Size == 0; }
   void clear() { Start = NULL; Size = 0; }

   void assign(const char *nStart, const char *nStop) { Start = nStart; Size = nStop - nStart; }
   void assign(const char *nStart, size_t nSize) { Start = nStart; Size = nSize; }

   size_t length() const { return Size; }
   size_t size() const { return Size; }

   typedef const char *const_iterator;
   const char *begin() const { return Start; }
   const char *end() const { return Start + Size; }

   char operator [](size_t index) const { return Start[index]; }

   operator std::string() { std::string Str; Str.assign(Start, Size); return Str; }
};

int stringcmp(const std::string &lhs, const char *rhsb, const char *rhse);
inline bool operator ==(const std::string &lhs, const srkString &rhs) {
   return stringcmp(lhs, rhs.begin(), rhs.end()) == 0;
}

#endif

// -*- mode: cpp; mode: fold -*-
// Description								/*{{{*/
// $Id: indexfile.h,v 1.6.2.1 2003/12/24 23:09:17 mdz Exp $
/* ######################################################################

   Index File - Abstraction for an index of archive/source file.
   
   There are 4 primary sorts of index files, all represented by this 
   class:
   
   Binary index files 
   Binary translation files 
   Bianry index files decribing the local system
   Source index files
   
   They are all bundled together here, and the interfaces for 
   sources.list, acquire, cache gen and record parsing all use this class
   to acess the underlying representation.
   
   ##################################################################### */
									/*}}}*/
#ifndef PKGLIB_INDEXFILE_H
#define PKGLIB_INDEXFILE_H


#include <string>
#include <apt-pkg/pkgcache.h>
#include <apt-pkg/srcrecords.h>
#include <apt-pkg/pkgrecords.h>
    
using std::string;

class pkgAcquire;
class pkgCacheGenerator;
class OpProgress;
class pkgIndexFile
{
   protected:
   bool Trusted;
     
   public:

   class Type
   {
      public:
      
      // Global list of Items supported
      static Type **GlobalList;
      static unsigned long GlobalListLen;
      static Type *GetType(const char *Type);

      const char *Label;

      virtual pkgRecords::Parser *CreatePkgParser(pkgCache::PkgFileIterator /*File*/) const {return 0;};
      Type();
      virtual ~Type() {};
   };

   virtual const Type *GetType() const = 0;
   
   // Return descriptive strings of various sorts
   virtual string ArchiveInfo(pkgCache::VerIterator Ver) const;
   virtual string SourceInfo(pkgSrcRecords::Parser const &Record,
			     pkgSrcRecords::File const &File) const;
   virtual string Describe(bool Short = false) const = 0;   

   // Interface for acquire
   virtual string ArchiveURI(string /*File*/) const {return string();};

   // Interface for the record parsers
   virtual pkgSrcRecords::Parser *CreateSrcParser() const {return 0;};
   
   // Interface for the Cache Generator
   virtual bool Exists() const = 0;
   virtual bool HasPackages() const = 0;
   virtual unsigned long Size() const = 0;
   virtual bool Merge(pkgCacheGenerator &/*Gen*/,OpProgress &/*Prog*/) const {return false;};
   virtual bool MergeFileProvides(pkgCacheGenerator &/*Gen*/,OpProgress &/*Prog*/) const {return true;};
   virtual pkgCache::PkgFileIterator FindInCache(pkgCache &Cache) const;

   static bool TranslationsAvailable();
   static bool CheckLanguageCode(const char *Lang);
   static string LanguageCode();

   bool IsTrusted() const { return Trusted; };
   
   pkgIndexFile(bool Trusted): Trusted(Trusted) {};
   virtual ~pkgIndexFile() {};
};

#endif

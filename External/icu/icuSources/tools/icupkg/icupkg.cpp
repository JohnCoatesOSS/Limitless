/*
*******************************************************************************
*
*   Copyright (C) 2005-2006, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
*******************************************************************************
*   file name:  icupkg.cpp
*   encoding:   US-ASCII
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 2005jul29
*   created by: Markus W. Scherer
*
*   This tool operates on ICU data (.dat package) files.
*   It takes one as input, or creates an empty one, and can remove, add, and
*   extract data pieces according to command-line options.
*   At the same time, it swaps each piece to a consistent set of platform
*   properties as desired.
*   Useful as an install-time tool for shipping only one flavor of ICU data
*   and preparing data files for the target platform.
*   Also for customizing ICU data (pruning, augmenting, replacing) and for
*   taking it apart.
*   Subsumes functionality and implementation code from
*   gencmn, decmn, and icuswap tools.
*   Will not work with data DLLs (shared libraries).
*/

#include "unicode/utypes.h"
#include "unicode/putil.h"
#include "cstring.h"
#include "toolutil.h"
#include "uoptions.h"
#include "uparse.h"
#include "package.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// TODO: add --matchmode=regex for using the ICU regex engine for item name pattern matching?

// general definitions ----------------------------------------------------- ***

#define LENGTHOF(array) (int32_t)(sizeof(array)/sizeof((array)[0]))

// read a file list -------------------------------------------------------- ***

static const char *reservedChars="\"%&'()*+,-./:;<=>?_";

static const struct {
    const char *suffix;
    int32_t length;
} listFileSuffixes[]={
    { ".txt", 4 },
    { ".lst", 4 },
    { ".tmp", 4 }
};

/* check for multiple text file suffixes to see if this list name is a text file name */
static UBool
isListTextFile(const char *listname) {
    const char *listNameEnd=strchr(listname, 0);
    const char *suffix;
    int32_t i, length;
    for(i=0; i<LENGTHOF(listFileSuffixes); ++i) {
        suffix=listFileSuffixes[i].suffix;
        length=listFileSuffixes[i].length;
        if((listNameEnd-listname)>length && 0==memcmp(listNameEnd-length, suffix, length)) {
            return TRUE;
        }
    }
    return FALSE;
}

/*
 * Read a file list.
 * If the listname ends with ".txt", then read the list file
 * (in the system/ invariant charset).
 * If the listname ends with ".dat", then read the ICU .dat package file.
 * Otherwise, read the file itself as a single-item list.
 */
static Package *
readList(const char *filesPath, const char *listname, UBool readContents) {
    Package *listPkg;
    FILE *file;
    const char *listNameEnd;

    if(listname==NULL || listname[0]==0) {
        fprintf(stderr, "missing list file\n");
        return NULL;
    }

    listPkg=new Package();
    if(listPkg==NULL) {
        fprintf(stderr, "icupkg: not enough memory\n");
        exit(U_MEMORY_ALLOCATION_ERROR);
    }

    listNameEnd=strchr(listname, 0);
    if(isListTextFile(listname)) {
        // read the list file
        char line[1024];
        char *end;
        const char *start;

        file=fopen(listname, "r");
        if(file==NULL) {
            fprintf(stderr, "icupkg: unable to open list file \"%s\"\n", listname);
            delete listPkg;
            exit(U_FILE_ACCESS_ERROR);
        }

        while(fgets(line, sizeof(line), file)) {
            // remove comments
            end=strchr(line, '#');
            if(end!=NULL) {
                *end=0;
            } else {
                // remove trailing CR LF
                end=strchr(line, 0);
                while(line<end && (*(end-1)=='\r' || *(end-1)=='\n')) {
                    *--end=0;
                }
            }

            // check first non-whitespace character and
            // skip empty lines and
            // skip lines starting with reserved characters
            start=u_skipWhitespace(line);
            if(*start==0 || NULL!=strchr(reservedChars, *start)) {
                continue;
            }

            // take whitespace-separated items from the line
            for(;;) {
                // find whitespace after the item or the end of the line
                for(end=(char *)start; *end!=0 && *end!=' ' && *end!='\t'; ++end) {}
                if(*end==0) {
                    // this item is the last one on the line
                    end=NULL;
                } else {
                    // the item is terminated by whitespace, terminate it with NUL
                    *end=0;
                }
                if(readContents) {
                    listPkg->addFile(filesPath, start);
                } else {
                    listPkg->addItem(start);
                }

                // find the start of the next item or exit the loop
                if(end==NULL || *(start=u_skipWhitespace(end+1))==0) {
                    break;
                }
            }
        }
        fclose(file);
    } else if((listNameEnd-listname)>4 && 0==memcmp(listNameEnd-4, ".dat", 4)) {
        // read the ICU .dat package
        listPkg->readPackage(listname);
    } else {
        // list the single file itself
        if(readContents) {
            listPkg->addFile(filesPath, listname);
        } else {
            listPkg->addItem(listname);
        }
    }

    return listPkg;
}

// main() ------------------------------------------------------------------ ***

static void
printUsage(const char *pname, UBool isHelp) {
    FILE *where=isHelp ? stdout : stderr;

    fprintf(where,
            "%csage: %s [-h|-?|--help ] [-tl|-tb|-te] [-c] [-C comment]\n"
            "\t[-a list] [-r list] [-x list] [-l]\n"
            "\t[-s path] [-d path] [-w] [-m mode]\n"
            "\tinfilename [outfilename]\n",
            isHelp ? 'U' : 'u', pname);
    if(isHelp) {
        fprintf(where,
            "\n"
            "Read the input ICU .dat package file, modify it according to the options,\n"
            "swap it to the desired platform properties (charset & endianness),\n"
            "and optionally write the resulting ICU .dat package to the output file.\n"
            "Items are removed, then added, then extracted and listed.\n"
            "An ICU .dat package is written if items are removed or added,\n"
            "or if the input and output filenames differ,\n"
            "or if the --writepkg (-w) option is set.\n");
        fprintf(where,
            "\n"
            "If the input filename is \"new\" then an empty package is created.\n"
            "If the output filename is missing, then it is automatically generated\n"
            "from the input filename: If the input filename ends with an l, b, or e\n"
            "matching its platform properties, then the output filename will\n"
            "contain the letter from the -t (--type) option.\n");
        fprintf(where,
            "\n"
            "This tool can also be used to just swap a single ICU data file, replacing the\n"
            "former icuswap tool. For this mode, provide the infilename (and optional\n"
            "outfilename) for a non-package ICU data file.\n"
            "Allowed options include -t, -w, -s and -d.\n"
            "The filenames can be absolute, or relative to the source/dest dir paths.\n"
            "Other options are not allowed in this mode.\n");
        fprintf(where,
            "\n"
            "Options:\n"
            "\t(Only the last occurrence of an option is used.)\n"
            "\n"
            "\t-h or -? or --help    print this message and exit\n");
        fprintf(where,
            "\n"
            "\t-tl or --type l   output for little-endian/ASCII charset family\n"
            "\t-tb or --type b   output for big-endian/ASCII charset family\n"
            "\t-te or --type e   output for big-endian/EBCDIC charset family\n"
            "\t                  The output type defaults to the input type.\n"
            "\n"
            "\t-c or --copyright include the ICU copyright notice\n"
            "\t-C comment or --comment comment   include a comment string\n");
        fprintf(where,
            "\n"
            "\t-a list or --add list      add items to the package\n"
            "\t-r list or --remove list   remove items from the package\n"
            "\t-x list or --extract list  extract items from the package\n"
            "\tThe list can be a single item's filename,\n"
            "\tor a .txt filename with a list of item filenames,\n"
            "\tor an ICU .dat package filename.\n");
        fprintf(where,
            "\n"
            "\t-w or --writepkg  write the output package even if no items are removed\n"
            "\t                  or added (e.g., for only swapping the data)\n");
        fprintf(where,
            "\n"
            "\t-m mode or --matchmode mode  set the matching mode for item names with\n"
            "\t                             wildcards\n"
            "\t        noslash: the '*' wildcard does not match the '/' tree separator\n");
        /*
         * Usage text columns, starting after the initial TAB.
         *      1         2         3         4         5         6         7         8
         *     901234567890123456789012345678901234567890123456789012345678901234567890
         */
        fprintf(where,
            "\n"
            "\tList file syntax: Items are listed on one or more lines and separated\n"
            "\tby whitespace (space+tab).\n"
            "\tComments begin with # and are ignored. Empty lines are ignored.\n"
            "\tLines where the first non-whitespace character is one of %s\n"
            "\tare also ignored, to reserve for future syntax.\n",
            reservedChars);
        fprintf(where,
            "\tItems for removal or extraction may contain a single '*' wildcard\n"
            "\tcharacter. The '*' matches zero or more characters.\n"
            "\tIf --matchmode noslash (-m noslash) is set, then the '*'\n"
            "\tdoes not match '/'.\n");
        fprintf(where,
            "\n"
            "\tItems must be listed relative to the package, and the --sourcedir or\n"
            "\tthe --destdir path will be prepended.\n"
            "\tThe paths are only prepended to item filenames while adding or\n"
            "\textracting items, not to ICU .dat package or list filenames.\n"
            "\t\n"
            "\tPaths may contain '/' instead of the platform's\n"
            "\tfile separator character, and are converted as appropriate.\n");
        fprintf(where,
            "\n"
            "\t-s path or --sourcedir path  directory for the --add items\n"
            "\t-d path or --destdir path    directory for the --extract items\n"
            "\n"
            "\t-l or --list                 list the package items to stdout\n"
            "\t                             (after modifying the package)\n");
    }
}

static UOption options[]={
    UOPTION_HELP_H,
    UOPTION_HELP_QUESTION_MARK,
    UOPTION_DEF("type", 't', UOPT_REQUIRES_ARG),

    UOPTION_COPYRIGHT,
    UOPTION_DEF("comment", 'C', UOPT_REQUIRES_ARG),

    UOPTION_SOURCEDIR,
    UOPTION_DESTDIR,

    UOPTION_DEF("writepkg", 'w', UOPT_NO_ARG),

    UOPTION_DEF("matchmode", 'm', UOPT_REQUIRES_ARG),

    UOPTION_DEF("add", 'a', UOPT_REQUIRES_ARG),
    UOPTION_DEF("remove", 'r', UOPT_REQUIRES_ARG),
    UOPTION_DEF("extract", 'x', UOPT_REQUIRES_ARG),

    UOPTION_DEF("list", 'l', UOPT_NO_ARG)
};

enum {
    OPT_HELP_H,
    OPT_HELP_QUESTION_MARK,
    OPT_OUT_TYPE,

    OPT_COPYRIGHT,
    OPT_COMMENT,

    OPT_SOURCEDIR,
    OPT_DESTDIR,

    OPT_WRITEPKG,

    OPT_MATCHMODE,

    OPT_ADD_LIST,
    OPT_REMOVE_LIST,
    OPT_EXTRACT_LIST,

    OPT_LIST_ITEMS,

    OPT_COUNT
};

static UBool
isPackageName(const char *filename) {
    int32_t len;

    len=(int32_t)strlen(filename)-4; /* -4: subtract the length of ".dat" */
    return (UBool)(len>0 && 0==strcmp(filename+len, ".dat"));
}

extern int
main(int argc, char *argv[]) {
    const char *pname, *sourcePath, *destPath, *inFilename, *outFilename, *outComment;
    char outType;
    UBool isHelp, isModified, isPackage;

    Package *pkg, *listPkg;

    U_MAIN_INIT_ARGS(argc, argv);

    /* get the program basename */
    pname=findBasename(argv[0]);

    argc=u_parseArgs(argc, argv, LENGTHOF(options), options);
    isHelp=options[OPT_HELP_H].doesOccur || options[OPT_HELP_QUESTION_MARK].doesOccur;
    if(isHelp) {
        printUsage(pname, TRUE);
        return U_ZERO_ERROR;
    }
    if(argc<2 || 3<argc) {
        printUsage(pname, FALSE);
        return U_ILLEGAL_ARGUMENT_ERROR;
    }

    pkg=new Package;
    if(pkg==NULL) {
        fprintf(stderr, "icupkg: not enough memory\n");
        return U_MEMORY_ALLOCATION_ERROR;
    }
    isModified=FALSE;

    if(options[OPT_SOURCEDIR].doesOccur) {
        sourcePath=options[OPT_SOURCEDIR].value;
    } else {
        // work relative to the current working directory
        sourcePath=NULL;
    }
    if(options[OPT_DESTDIR].doesOccur) {
        destPath=options[OPT_DESTDIR].value;
    } else {
        // work relative to the current working directory
        destPath=NULL;
    }

    if(0==strcmp(argv[1], "new")) {
        inFilename=NULL;
        isPackage=TRUE;
    } else {
        inFilename=argv[1];
        if(isPackageName(inFilename)) {
            pkg->readPackage(inFilename);
            isPackage=TRUE;
        } else {
            /* swap a single file (icuswap replacement) rather than work on a package */
            pkg->addFile(sourcePath, inFilename);
            isPackage=FALSE;
        }
    }

    if(argc>=3) {
        outFilename=argv[2];
        if(0!=strcmp(argv[1], argv[2])) {
            isModified=TRUE;
        }
    } else if(isPackage) {
        outFilename=NULL;
    } else /* !isPackage */ {
        outFilename=inFilename;
        isModified=(UBool)(sourcePath!=destPath);
    }

    /* parse the output type option */
    if(options[OPT_OUT_TYPE].doesOccur) {
        const char *type=options[OPT_OUT_TYPE].value;
        if(type[0]==0 || type[1]!=0) {
            /* the type must be exactly one letter */
            printUsage(pname, FALSE);
            return U_ILLEGAL_ARGUMENT_ERROR;
        }
        outType=type[0];
        switch(outType) {
        case 'l':
        case 'b':
        case 'e':
            break;
        default:
            printUsage(pname, FALSE);
            return U_ILLEGAL_ARGUMENT_ERROR;
        }

        /*
         * Set the isModified flag if the output type differs from the
         * input package type.
         * If we swap a single file, just assume that we are modifying it.
         * The Package class does not give us access to the item and its type.
         */
        isModified=(UBool)(!isPackage || outType!=pkg->getInType());
    } else if(isPackage) {
        outType=pkg->getInType(); // default to input type
    } else /* !isPackage: swap single file */ {
        outType=0; /* tells extractItem() to not swap */
    }

    if(options[OPT_WRITEPKG].doesOccur) {
        isModified=TRUE;
    }

    if(!isPackage) {
        /*
         * icuswap tool replacement: Only swap a single file.
         * Check that irrelevant options are not set.
         */
        if( options[OPT_COMMENT].doesOccur ||
            options[OPT_COPYRIGHT].doesOccur ||
            options[OPT_MATCHMODE].doesOccur ||
            options[OPT_REMOVE_LIST].doesOccur ||
            options[OPT_ADD_LIST].doesOccur ||
            options[OPT_EXTRACT_LIST].doesOccur ||
            options[OPT_LIST_ITEMS].doesOccur
        ) {
            printUsage(pname, FALSE);
            return U_ILLEGAL_ARGUMENT_ERROR;
        }
        if(isModified) {
            pkg->extractItem(destPath, outFilename, 0, outType);
        }

        delete pkg;
        return 0;
    }

    /* Work with a package. */

    if(options[OPT_COMMENT].doesOccur) {
        outComment=options[OPT_COMMENT].value;
    } else if(options[OPT_COPYRIGHT].doesOccur) {
        outComment=U_COPYRIGHT_STRING;
    } else {
        outComment=NULL;
    }

    if(options[OPT_MATCHMODE].doesOccur) {
        if(0==strcmp(options[OPT_MATCHMODE].value, "noslash")) {
            pkg->setMatchMode(Package::MATCH_NOSLASH);
        } else {
            printUsage(pname, FALSE);
            return U_ILLEGAL_ARGUMENT_ERROR;
        }
    }

    /* remove items */
    if(options[OPT_REMOVE_LIST].doesOccur) {
        listPkg=readList(NULL, options[OPT_REMOVE_LIST].value, FALSE);
        if(listPkg!=NULL) {
            pkg->removeItems(*listPkg);
            delete listPkg;
            isModified=TRUE;
        } else {
            printUsage(pname, FALSE);
            return U_ILLEGAL_ARGUMENT_ERROR;
        }
    }

    /*
     * add items
     * use a separate Package so that its memory and items stay around
     * as long as the main Package
     */
    if(options[OPT_ADD_LIST].doesOccur) {
        listPkg=readList(sourcePath, options[OPT_ADD_LIST].value, TRUE);
        if(listPkg!=NULL) {
            pkg->addItems(*listPkg);
            delete listPkg;
            isModified=TRUE;
        } else {
            printUsage(pname, FALSE);
            return U_ILLEGAL_ARGUMENT_ERROR;
        }
    }

    /* extract items */
    if(options[OPT_EXTRACT_LIST].doesOccur) {
        listPkg=readList(NULL, options[OPT_EXTRACT_LIST].value, FALSE);
        if(listPkg!=NULL) {
            pkg->extractItems(destPath, *listPkg, outType);
            delete listPkg;
        } else {
            printUsage(pname, FALSE);
            return U_ILLEGAL_ARGUMENT_ERROR;
        }
    }

    /* list items */
    if(options[OPT_LIST_ITEMS].doesOccur) {
        pkg->listItems(stdout);
    }

    /* check dependencies between items */
    if(!pkg->checkDependencies()) {
        /* some dependencies are not fulfilled */
        return U_MISSING_RESOURCE_ERROR;
    }

    /* write the output .dat package if there are any modifications */
    if(isModified) {
        char outFilenameBuffer[1024]; // for auto-generated output filename, if necessary

        if(outFilename==NULL || outFilename[0]==0) {
            if(inFilename==NULL || inFilename[0]==0) {
                fprintf(stderr, "icupkg: unable to auto-generate an output filename if there is no input filename\n");
                exit(U_ILLEGAL_ARGUMENT_ERROR);
            }

            /*
             * auto-generate a filename:
             * copy the inFilename,
             * and if the last basename character matches the input file's type,
             * then replace it with the output file's type
             */
            char suffix[6]="?.dat";
            char *s;

            suffix[0]=pkg->getInType();
            strcpy(outFilenameBuffer, inFilename);
            s=strchr(outFilenameBuffer, 0);
            if((s-outFilenameBuffer)>5 && 0==memcmp(s-5, suffix, 5)) {
                *(s-5)=outType;
            }
            outFilename=outFilenameBuffer;
        }
        pkg->writePackage(outFilename, outType, outComment);
    }

    delete pkg;
    return 0;
}

/*
 * Hey, Emacs, please set the following:
 *
 * Local Variables:
 * indent-tabs-mode: nil
 * End:
 *
 */

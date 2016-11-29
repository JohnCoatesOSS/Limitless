//
//  Package.mm
//  Cydia
//
//  Created on 8/30/16.
//

#import "Package.h"
#import "CydiaRelation.h"
#import "DisplayHelpers.hpp"
#import "Source.h"
#import "Standard.h"

#include <fstream>

@implementation Package

- (NSString *) description {
    return [NSString stringWithFormat:@"<Package:%@>", static_cast<NSString *>(name_)];
}

- (void) dealloc {
    if (!pooled_)
        delete pool_;
    if (parsed_ != NULL)
        delete parsed_;
    [super dealloc];
}

+ (NSString *) webScriptNameForSelector:(SEL)selector {
    if (false);
    else if (selector == @selector(clear))
        return @"clear";
    else if (selector == @selector(getField:))
        return @"getField";
    else if (selector == @selector(getRecord))
        return @"getRecord";
    else if (selector == @selector(hasTag:))
        return @"hasTag";
    else if (selector == @selector(install))
        return @"install";
    else if (selector == @selector(remove))
        return @"remove";
    else
        return nil;
}

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector {
    return [self webScriptNameForSelector:selector] == nil;
}

+ (NSArray *) _attributeKeys {
    return [NSArray arrayWithObjects:
            @"applications",
            @"architecture",
            @"author",
            @"depiction",
            @"essential",
            @"homepage",
            @"icon",
            @"id",
            @"installed",
            @"latest",
            @"longDescription",
            @"longSection",
            @"maintainer",
            @"md5sum",
            @"mode",
            @"name",
            @"purposes",
            @"relations",
            @"section",
            @"selection",
            @"shortDescription",
            @"shortSection",
            @"simpleSection",
            @"size",
            @"source",
            @"state",
            @"support",
            @"tags",
            @"upgraded",
            @"warnings",
            nil];
}

- (NSArray *) attributeKeys {
    return [[self class] _attributeKeys];
}

+ (BOOL) isKeyExcludedFromWebScript:(const char *)name {
    return ![[self _attributeKeys] containsObject:[NSString stringWithUTF8String:name]] && [super isKeyExcludedFromWebScript:name];
}

- (NSArray *) relations {
    @synchronized (database_) {
        NSMutableArray *relations([NSMutableArray arrayWithCapacity:16]);
        for (pkgCache::DepIterator dep(version_.DependsList()); !dep.end(); ++dep)
            [relations addObject:[[[CydiaRelation alloc] initWithIterator:dep] autorelease]];
        return relations;
    } }

- (NSString *) architecture {
    [self parse];
    @synchronized (database_) {
        return parsed_->architecture_.empty() ? [NSNull null] : (id) parsed_->architecture_;
    } }

- (NSString *) getField:(NSString *)name {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return nil;
        
        pkgRecords::Parser &parser([database_ records]->Lookup(file_));
        
        const char *start, *end;
        if (!parser.Find([name UTF8String], start, end))
            return (NSString *) [NSNull null];
        
        return [NSString stringWithString:[(NSString *) CYStringCreate(start, end - start) autorelease]];
    } }

- (NSString *) getRecord {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return nil;
        
        pkgRecords::Parser &parser([database_ records]->Lookup(file_));
        
        const char *start, *end;
        parser.GetRec(start, end);
        
        return [NSString stringWithString:[(NSString *) CYStringCreate(start, end - start) autorelease]];
    } }

- (void) parse {
    if (parsed_ != NULL)
        return;
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return;
        
        ParsedPackage *parsed(new ParsedPackage);
        parsed_ = parsed;
        
        _profile(Package$parse)
        pkgRecords::Parser *parser;
        
        _profile(Package$parse$Lookup)
        parser = &[database_ records]->Lookup(file_);
        _end
        
        CYString bugs;
        CYString website;
        
        _profile(Package$parse$Find)
        struct {
            const char *name_;
            CYString *value_;
        } names[] = {
            {"architecture", &parsed->architecture_},
            {"icon", &parsed->icon_},
            {"depiction", &parsed->depiction_},
            {"homepage", &parsed->homepage_},
            {"website", &website},
            {"bugs", &bugs},
            {"support", &parsed->support_},
            {"author", &parsed->author_},
            {"md5sum", &parsed->md5sum_},
        };
        
        for (size_t i(0); i != sizeof(names) / sizeof(names[0]); ++i) {
            const char *start, *end;
            
            if (parser->Find(names[i].name_, start, end)) {
                CYString &value(*names[i].value_);
                _profile(Package$parse$Value)
                value.set(pool_, start, end - start);
                _end
            }
        }
        _end
        
        _profile(Package$parse$Tagline)
        const char *start, *end;
        if (parser->ShortDesc(start, end)) {
            const char *stop(reinterpret_cast<const char *>(memchr(start, '\n', end - start)));
            if (stop == NULL)
                stop = end;
            while (stop != start && stop[-1] == '\r')
                --stop;
            parsed->tagline_.set(pool_, start, stop - start);
        }
        _end
        
        _profile(Package$parse$Retain)
        if (parsed->homepage_.empty())
            parsed->homepage_ = website;
        if (parsed->homepage_ == parsed->depiction_)
            parsed->homepage_.clear();
        if (parsed->support_.empty())
            parsed->support_ = bugs;
        _end
        _end
    } }

- (Package *) initWithVersion:(pkgCache::VerIterator)version withZone:(NSZone *)zone inPool:(CYPool *)pool database:(Database *)database {
    if ((self = [super init]) != nil) {
        _profile(Package$initWithVersion)
        if (pool == NULL)
            pool_ = new CYPool();
        else {
            pool_ = pool;
            pooled_ = true;
        }
        
        database_ = database;
        era_ = [database era];
        
        version_ = version;
        
        pkgCache::PkgIterator iterator(version.ParentPkg());
        iterator_ = iterator;
        
        _profile(Package$initWithVersion$Version)
        file_ = version_.FileList();
        _end
        
        _profile(Package$initWithVersion$Cache)
        name_.set(NULL, iterator.Display());
        
        latest_.set(NULL, StripVersion_(version_.VerStr()));
        
        pkgCache::VerIterator current(iterator.CurrentVer());
        if (!current.end())
            installed_.set(NULL, StripVersion_(current.VerStr()));
        _end
        
        _profile(Package$initWithVersion$Transliterate) do {
            if (CollationTransl_ == NULL)
                break;
            if (name_.empty())
                break;
            
            _profile(Package$initWithVersion$Transliterate$utf8)
            const uint8_t *data(reinterpret_cast<const uint8_t *>(name_.data()));
            for (size_t i(0), e(name_.size()); i != e; ++i)
                if (data[i] >= 0x80)
                    goto extended;
            break; extended:;
            _end
            
            UErrorCode code(U_ZERO_ERROR);
            int32_t length;
            
            _profile(Package$initWithVersion$Transliterate$u_strFromUTF8WithSub)
            CollationString_.resize(name_.size());
            u_strFromUTF8WithSub(&CollationString_[0], CollationString_.size(), &length, name_.data(), name_.size(), 0xfffd, NULL, &code);
            if (!U_SUCCESS(code))
                break;
            CollationString_.resize(length);
            _end
            
            _profile(Package$initWithVersion$Transliterate$utrans_trans)
            length = CollationString_.size();
            utrans_trans(CollationTransl_, reinterpret_cast<UReplaceable *>(&CollationString_), &CollationUCalls_, 0, &length, &code);
            if (!U_SUCCESS(code))
                break;
            _assert(CollationString_.size() == length);
            _end
            
            _profile(Package$initWithVersion$Transliterate$u_strToUTF8WithSub$preflight)
            u_strToUTF8WithSub(NULL, 0, &length, CollationString_.data(), CollationString_.size(), 0xfffd, NULL, &code);
            if (code == U_BUFFER_OVERFLOW_ERROR)
                code = U_ZERO_ERROR;
            else if (!U_SUCCESS(code))
                break;
            _end
            
            char *transform;
            _profile(Package$initWithVersion$Transliterate$apr_palloc)
            transform = pool_->malloc<char>(length);
            _end
            _profile(Package$initWithVersion$Transliterate$u_strToUTF8WithSub$transform)
            u_strToUTF8WithSub(transform, length, NULL, CollationString_.data(), CollationString_.size(), 0xfffd, NULL, &code);
            if (!U_SUCCESS(code))
                break;
            _end
            
            transform_.set(NULL, transform, length);
        } while (false); _end
        
        _profile(Package$initWithVersion$Tags)
        pkgCache::TagIterator tag(iterator.TagList());
        if (!tag.end()) {
            tags_ = [NSMutableArray arrayWithCapacity:8];
            
            goto tag; for (; !tag.end(); ++tag) tag: {
                const char *name(tag.Name());
                NSString *string((NSString *) CYStringCreate(name));
                if (string == nil)
                    continue;
                
                [tags_ addObject:[string autorelease]];
                
                if (role_ == 0 && strncmp(name, "role::", 6) == 0 /*&& strcmp(name, "role::leaper") != 0*/) {
                    if (strcmp(name + 6, "enduser") == 0)
                        role_ = 1;
                    else if (strcmp(name + 6, "hacker") == 0)
                        role_ = 2;
                    else if (strcmp(name + 6, "developer") == 0)
                        role_ = 3;
                    else if (strcmp(name + 6, "cydia") == 0)
                        role_ = 7;
                    else
                        role_ = 4;
                }
                
                if (strncmp(name, "cydia::", 7) == 0) {
                    if (strcmp(name + 7, "essential") == 0)
                        essential_ = true;
                    else if (strcmp(name + 7, "obsolete") == 0)
                        obsolete_ = true;
                }
            }
        }
        _end
        
        _profile(Package$initWithVersion$Metadata)
        const char *mixed(iterator.Name());
        size_t size(strlen(mixed));
        static const size_t prefix(sizeof("/var/lib/dpkg/info/") - 1);
        char lower[prefix + size + 5 + 1];
        
        for (size_t i(0); i != size; ++i)
            lower[prefix + i] = mixed[i] | 0x20;
        
        if (!installed_.empty()) {
            memcpy(lower, "/var/lib/dpkg/info/", prefix);
            memcpy(lower + prefix + size, ".list", 6);
            struct stat info;
            if (stat(lower, &info) != -1)
                upgraded_ = info.st_birthtime;
        }
        
        PackageValue *metadata(PackageFind(lower + prefix, size));
        metadata_ = metadata;
        
        id_.set(NULL, metadata->name_, size);
        
        const char *latest(version_.VerStr());
        size_t length(strlen(latest));
        
        uint16_t vhash(hashlittle(latest, length));
        
        size_t capped(std::min<size_t>(8, length));
        latest = latest + length - capped;
        
        if (metadata->first_ == 0)
            metadata->first_ = now_;
        
        if (metadata->vhash_ != vhash || strncmp(metadata->version_, latest, sizeof(metadata->version_)) != 0) {
            strncpy(metadata->version_, latest, sizeof(metadata->version_));
            metadata->vhash_ = vhash;
            metadata->last_ = now_;
        } else if (metadata->last_ == 0)
            metadata->last_ = metadata->first_;
        _end
        
        _profile(Package$initWithVersion$Section)
        section_ = version_.Section();
        _end
        
        _profile(Package$initWithVersion$Flags)
        essential_ |= ((iterator->Flags & pkgCache::Flag::Essential) == 0 ? NO : YES);
        ignored_ = iterator->SelectedState == pkgCache::State::Hold;
        _end
        _end } return self;
}

+ (Package *) packageWithIterator:(pkgCache::PkgIterator)iterator withZone:(NSZone *)zone inPool:(CYPool *)pool database:(Database *)database {
    pkgCache::VerIterator version;
    
    _profile(Package$packageWithIterator$GetCandidateVer)
    version = [database policy]->GetCandidateVer(iterator);
    _end
    
    if (version.end())
        return nil;
    
    Package *package;
    
    _profile(Package$packageWithIterator$Allocate)
    package = [Package allocWithZone:zone];
    _end
    
    _profile(Package$packageWithIterator$Initialize)
    package = [package
               initWithVersion:version
               withZone:zone
               inPool:pool
               database:database
               ];
    _end
    
    _profile(Package$packageWithIterator$Autorelease)
    package = [package autorelease];
    _end
    
    return package;
}

- (pkgCache::PkgIterator) iterator {
    return iterator_;
}

- (NSArray *) downgrades {
    NSMutableArray *versions([NSMutableArray arrayWithCapacity:4]);
    
    for (auto version(iterator_.VersionList()); !version.end(); ++version) {
        if (version == version_)
            continue;
        Package *package([[[Package allocWithZone:NULL] initWithVersion:version withZone:NULL inPool:NULL database:database_] autorelease]);
        if ([package source] == nil)
            continue;
        [versions addObject:package];
    }
    
    return versions;
}

- (NSString *) section {
    if (section$_ == nil) {
        if (section_ == NULL)
            return nil;
        
        _profile(Package$section$mappedSectionForPointer)
        section$_ = [database_ mappedSectionForPointer:section_];
        _end
    } return section$_;
}

- (NSString *) simpleSection {
    if (NSString *section = [self section])
        return Simplify(section);
    else
        return nil;
}

- (NSString *) longSection {
    return LocalizeSection([self section]);
}

- (NSString *) shortSection {
    return [[NSBundle mainBundle] localizedStringForKey:[self simpleSection] value:nil table:@"Sections"];
}

- (NSString *) uri {
    return nil;
#if 0
    pkgIndexFile *index;
    pkgCache::PkgFileIterator file(file_.File());
    if (![database_ list].FindIndex(file, index))
        return nil;
    return [NSString stringWithUTF8String:iterator_->Path];
    //return [NSString stringWithUTF8String:file.Site()];
    //return [NSString stringWithUTF8String:index->ArchiveURI(file.FileName()).c_str()];
#endif
}

- (MIMEAddress *) maintainer {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return nil;
        
        pkgRecords::Parser *parser = &[database_ records]->Lookup(file_);
        const std::string &maintainer(parser->Maintainer());
        return maintainer.empty() ? nil : [MIMEAddress addressWithString:[NSString stringWithUTF8String:maintainer.c_str()]];
    } }

- (NSString *) md5sum {
    return parsed_ == NULL ? nil : (id) parsed_->md5sum_;
}

- (size_t) size {
    @synchronized (database_) {
        if ([database_ era] != era_ || version_.end())
            return 0;
        
        return version_->InstalledSize;
    } }

- (NSString *) longDescription {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return nil;
        
        pkgRecords::Parser *parser = &[database_ records]->Lookup(file_);
        NSString *description([NSString stringWithUTF8String:parser->LongDesc().c_str()]);
        
        NSArray *lines = [description componentsSeparatedByString:@"\n"];
        NSMutableArray *trimmed = [NSMutableArray arrayWithCapacity:([lines count] - 1)];
        if ([lines count] < 2)
            return nil;
        
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
        for (size_t i(1), e([lines count]); i != e; ++i) {
            NSString *trim = [[lines objectAtIndex:i] stringByTrimmingCharactersInSet:whitespace];
            [trimmed addObject:trim];
        }
        
        return [trimmed componentsJoinedByString:@"\n"];
    } }

- (NSString *) shortDescription {
    if (parsed_ != NULL)
        return static_cast<NSString *>(parsed_->tagline_);
    
    @synchronized (database_) {
        pkgRecords::Parser &parser([database_ records]->Lookup(file_));
        
        const char *start, *end;
        if (!parser.ShortDesc(start, end))
            return nil;
        
        if (end - start > 200)
            end = start + 200;
        
        /*
         if (const char *stop = reinterpret_cast<const char *>(memchr(start, '\n', end - start)))
         end = stop;
         
         while (end != start && end[-1] == '\r')
         --end;
         */
        
        return [(id) CYStringCreate(start, end - start) autorelease];
    } }

- (unichar) index {
    _profile(Package$index)
    CFStringRef name((CFStringRef) [self name]);
    if (CFStringGetLength(name) == 0)
        return '#';
    UniChar character(CFStringGetCharacterAtIndex(name, 0));
    if (!CFUniCharIsMemberOf(character, kCFUniCharLetterCharacterSet))
        return '#';
    return toupper(character);
    _end
}

- (PackageValue *) metadata {
    return metadata_;
}

- (time_t) seen {
    PackageValue *metadata([self metadata]);
    return metadata->subscribed_ ? metadata->last_ : metadata->first_;
}

- (bool) subscribed {
    return [self metadata]->subscribed_;
}

- (bool) setSubscribed:(bool)subscribed {
    PackageValue *metadata([self metadata]);
    if (metadata->subscribed_ == subscribed)
        return false;
    metadata->subscribed_ = subscribed;
    return true;
}

- (BOOL) ignored {
    return ignored_;
}

- (NSString *) latest {
    return latest_;
}

- (NSString *) installed {
    return installed_;
}

- (BOOL) uninstalled {
    return installed_.empty();
}

- (BOOL) upgradableAndEssential:(BOOL)essential {
    _profile(Package$upgradableAndEssential)
    pkgCache::VerIterator current(iterator_.CurrentVer());
    if (current.end())
        return essential && essential_;
    else
        return version_ != current;
    _end
}

- (BOOL) essential {
    return essential_;
}

- (BOOL) broken {
    return [database_ cache][iterator_].InstBroken();
}

- (BOOL) unfiltered {
    _profile(Package$unfiltered$obsolete)
    if (_unlikely(obsolete_))
        return false;
    _end
    
    _profile(Package$unfiltered$role)
    if (_unlikely(role_ > 3))
        return false;
    _end
    
    return true;
}

- (BOOL) visible {
    if (![self unfiltered])
        return false;
    
    NSString *section;
    
    _profile(Package$visible$section)
    section = [self section];
    _end
    
    _profile(Package$visible$isSectionVisible)
    if (!isSectionVisible(section))
        return false;
    _end
    
    return true;
}

- (BOOL) half {
    unsigned char current(iterator_->CurrentState);
    return current == pkgCache::State::HalfConfigured || current == pkgCache::State::HalfInstalled;
}

- (BOOL) halfConfigured {
    return iterator_->CurrentState == pkgCache::State::HalfConfigured;
}

- (BOOL) halfInstalled {
    return iterator_->CurrentState == pkgCache::State::HalfInstalled;
}

- (BOOL) hasMode {
    @synchronized (database_) {
        if ([database_ era] != era_ || iterator_.end())
            return NO;
        
        pkgDepCache::StateCache &state([database_ cache][iterator_]);
        return state.Mode != pkgDepCache::ModeKeep;
    } }

- (NSString *) mode {
    @synchronized (database_) {
        if ([database_ era] != era_ || iterator_.end())
            return nil;
        
        pkgDepCache::StateCache &state([database_ cache][iterator_]);
        
        switch (state.Mode) {
            case pkgDepCache::ModeDelete:
                if ((state.iFlags & pkgDepCache::Purge) != 0)
                    return @"PURGE";
                else
                    return @"REMOVE";
            case pkgDepCache::ModeKeep:
                if ((state.iFlags & pkgDepCache::ReInstall) != 0)
                    return @"REINSTALL";
                /*else if ((state.iFlags & pkgDepCache::AutoKept) != 0)
                 return nil;*/
                else
                    return nil;
            case pkgDepCache::ModeInstall:
                /*if ((state.iFlags & pkgDepCache::ReInstall) != 0)
                 return @"REINSTALL";
                 else*/ switch (state.Status) {
                     case -1:
                         return @"DOWNGRADE";
                     case 0:
                         return @"INSTALL";
                     case 1:
                         return @"UPGRADE";
                     case 2:
                         return @"NEW_INSTALL";
                         _nodefault
                 }
                _nodefault
        }
    } }

- (NSString *) id {
    return id_;
}

- (NSString *) name {
    return name_.empty() ? id_ : name_;
}

- (UIImage *) icon {
    NSString *section = [self simpleSection];
    
    UIImage *icon(nil);
    if (parsed_ != NULL)
        if (NSString *href = parsed_->icon_)
            if ([href hasPrefix:@"file:///"])
                icon = [UIImage imageAtPath:[[href substringFromIndex:7] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (icon == nil) if (section != nil)
        icon = [UIImage imageAtPath:[NSString stringWithFormat:@"%@/Sections/%@.png", App_, [section stringByReplacingOccurrencesOfString:@" " withString:@"_"]]];
    if (icon == nil) if (Source *source = [self source]) if (NSString *dicon = [source defaultIcon])
        if ([dicon hasPrefix:@"file:///"])
            icon = [UIImage imageAtPath:[[dicon substringFromIndex:7] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (icon == nil) {
        icon = [UIImage imageNamed:[section stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        if (icon == nil) {
            icon = [UIImage imageNamed:@"unknown.png"];
        }
    }
    return icon;
}

- (NSString *) homepage {
    return parsed_ == NULL ? nil : static_cast<NSString *>(parsed_->homepage_);
}

- (NSString *) depiction {
    return parsed_ != NULL && !parsed_->depiction_.empty() ? parsed_->depiction_ : [[self source] depictionForPackage:id_];
}

- (MIMEAddress *) author {
    return parsed_ == NULL || parsed_->author_.empty() ? nil : [MIMEAddress addressWithString:parsed_->author_];
}

- (NSString *) support {
    return parsed_ != NULL && !parsed_->support_.empty() ? parsed_->support_ : [[self source] supportForPackage:id_];
}

- (NSArray *) files {
    NSString *path = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.list", static_cast<NSString *>(id_)];
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:128];
    
    std::ifstream fin;
    fin.open([path UTF8String]);
    if (!fin.is_open())
        return nil;
    
    std::string line;
    while (std::getline(fin, line))
        [files addObject:[NSString stringWithUTF8String:line.c_str()]];
    
    return files;
}

- (NSString *) state {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return nil;
        
        switch (iterator_->CurrentState) {
            case pkgCache::State::NotInstalled:
                return @"NotInstalled";
            case pkgCache::State::UnPacked:
                return @"UnPacked";
            case pkgCache::State::HalfConfigured:
                return @"HalfConfigured";
            case pkgCache::State::HalfInstalled:
                return @"HalfInstalled";
            case pkgCache::State::ConfigFiles:
                return @"ConfigFiles";
            case pkgCache::State::Installed:
                return @"Installed";
            case pkgCache::State::TriggersAwaited:
                return @"TriggersAwaited";
            case pkgCache::State::TriggersPending:
                return @"TriggersPending";
        }
        
        return (NSString *) [NSNull null];
    } }

- (NSString *) selection {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return nil;
        
        switch (iterator_->SelectedState) {
            case pkgCache::State::Unknown:
                return @"Unknown";
            case pkgCache::State::Install:
                return @"Install";
            case pkgCache::State::Hold:
                return @"Hold";
            case pkgCache::State::DeInstall:
                return @"DeInstall";
            case pkgCache::State::Purge:
                return @"Purge";
        }
        
        return (NSString *) [NSNull null];
    } }

- (NSArray *) warnings {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return nil;
        
        NSMutableArray *warnings([NSMutableArray arrayWithCapacity:4]);
        const char *name(iterator_.Name());
        
        size_t length(strlen(name));
        if (length < 2) invalid:
            [warnings addObject:UCLocalize("ILLEGAL_PACKAGE_IDENTIFIER")];
        else for (size_t i(0); i != length; ++i)
            if (
                /* XXX: technically this is not allowed */
                (name[i] < 'A' || name[i] > 'Z') &&
                (name[i] < 'a' || name[i] > 'z') &&
                (name[i] < '0' || name[i] > '9') &&
                (i == 0 || (name[i] != '+' && name[i] != '-' && name[i] != '.'))
                ) goto invalid;
        
        if (strcmp(name, "cydia") != 0) {
            bool cydia = false;
            bool user = false;
            bool _private = false;
            bool stash = false;
            bool dbstash = false;
            bool dsstore = false;
            
            bool repository = [[self section] isEqualToString:@"Repositories"];
            
            if (NSArray *files = [self files]) {
                for (NSString *file in files) {
                    if (!cydia && [file isEqualToString:@"/Applications/Cydia.app"]) {
                        cydia = true;
                    }
                    else if (!user && [file isEqualToString:@"/User"]) {
                        user = true;
                    }
                    else if (!_private && [file isEqualToString:@"/private"]) {
                        _private = true;
                    }
                    else if (!stash && [file isEqualToString:@"/var/stash"]) {
                        stash = true;
                    }
                    else if (!dbstash && [file isEqualToString:@"/var/db/stash"]) {
                        dbstash = true;
                    }
                    else if (!dsstore && [file hasSuffix:@"/.DS_Store"]) {
                        dsstore = true;
                    }
                }
            }
            
            /* XXX: this is not sensitive enough. only some folders are valid. */
            if (cydia && !repository)
                [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"Cydia.app"]];
            if (user)
                [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"/User"]];
            if (_private)
                [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"/private"]];
            if (stash)
                [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"/var/stash"]];
            if (dbstash)
                [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @"/var/db/stash"]];
            if (dsstore)
                [warnings addObject:[NSString stringWithFormat:UCLocalize("FILES_INSTALLED_TO"), @".DS_Store"]];
        }
        
        return [warnings count] == 0 ? nil : warnings;
    } }

- (NSArray *) applications {
    NSString *me([[NSBundle mainBundle] bundleIdentifier]);
    
    NSMutableArray *applications([NSMutableArray arrayWithCapacity:2]);
    
    static RegEx application_r("/Applications/(.*)\\.app/Info.plist");
    if (NSArray *files = [self files])
        for (NSString *file in files)
            if (application_r(file)) {
                NSDictionary *info([NSDictionary dictionaryWithContentsOfFile:file]);
                if (info == nil)
                    continue;
                NSString *id([info objectForKey:@"CFBundleIdentifier"]);
                if (id == nil || [id isEqualToString:me])
                    continue;
                
                NSString *display([info objectForKey:@"CFBundleDisplayName"]);
                if (display == nil)
                    display = application_r[1];
                
                NSString *bundle([file stringByDeletingLastPathComponent]);
                NSString *icon([info objectForKey:@"CFBundleIconFile"]);
                // XXX: maybe this should check if this is really a string, not just for length
                if (icon == nil || ![icon respondsToSelector:@selector(length)] || [icon length] == 0)
                    icon = @"icon.png";
                NSURL *url([NSURL fileURLWithPath:[bundle stringByAppendingPathComponent:icon]]);
                
                NSMutableArray *application([NSMutableArray arrayWithCapacity:2]);
                [applications addObject:application];
                
                [application addObject:id];
                [application addObject:display];
                [application addObject:url];
            }
    
    return [applications count] == 0 ? nil : applications;
}

- (Source *) source {
    if (source_ == nil) {
        @synchronized (database_) {
            if ([database_ era] != era_ || file_.end())
                source_ = (Source *) [NSNull null];
            else
                source_ = [database_ getSource:file_.File()] ?: (Source *) [NSNull null];
        }
    }
    
    return source_ == (Source *) [NSNull null] ? nil : source_;
}

- (time_t) upgraded {
    return upgraded_;
}

- (uint32_t) recent {
    return std::numeric_limits<uint32_t>::max() - upgraded_;
}

- (uint32_t) rank {
    return rank_;
}

- (BOOL) matches:(NSArray *)query {
    if (query == nil || [query count] == 0)
        return NO;
    
    rank_ = 0;
    
    NSString *string;
    NSRange range;
    NSUInteger length;
    
    string = [self name];
    length = [string length];
    
    if (length != 0)
        for (NSString *term in query) {
            range = [string rangeOfString:term options:MatchCompareOptions_];
            if (range.location != NSNotFound)
                rank_ -= 6 * 1000000 / length;
        }
    
    if (rank_ == 0) {
        string = [self id];
        length = [string length];
        
        if (length != 0)
            for (NSString *term in query) {
                range = [string rangeOfString:term options:MatchCompareOptions_];
                if (range.location != NSNotFound)
                    rank_ -= 6 * 1000000 / length;
            }
    }
    
    string = [self shortDescription];
    length = [string length];
    NSUInteger stop(std::min<NSUInteger>(length, 200));
    
    if (length != 0)
        for (NSString *term in query) {
            range = [string rangeOfString:term options:MatchCompareOptions_ range:NSMakeRange(0, stop)];
            if (range.location != NSNotFound)
                rank_ -= 2 * 100000;
        }
    
    return rank_ != 0;
}

- (NSArray *) tags {
    return tags_;
}

- (BOOL) hasTag:(NSString *)tag {
    return tags_ == nil ? NO : [tags_ containsObject:tag];
}

- (NSString *) primaryPurpose {
    for (NSString *tag in (NSArray *) tags_)
        if ([tag hasPrefix:@"purpose::"])
            return [tag substringFromIndex:9];
    return nil;
}

- (NSArray *) purposes {
    NSMutableArray *purposes([NSMutableArray arrayWithCapacity:2]);
    for (NSString *tag in (NSArray *) tags_)
        if ([tag hasPrefix:@"purpose::"])
            [purposes addObject:[tag substringFromIndex:9]];
    return [purposes count] == 0 ? nil : purposes;
}

- (bool) isCommercial {
    return [self hasTag:@"cydia::commercial"];
}

- (bool)isFavorited {
    
    return [[database_ currentFavorites] containsObject:self];
}
- (void) setIndex:(size_t)index {
    if (metadata_->index_ != index)
        metadata_->index_ = index;
}

- (CYString &) cyname {
    return !transform_.empty() ? transform_ : !name_.empty() ? name_ : id_;
}

- (uint32_t) compareBySection:(NSArray *)sections {
    NSString *section([self section]);
    for (size_t i(0), e([sections count]); i != e; ++i) {
        if ([section isEqualToString:[[sections objectAtIndex:i] name]])
            return i;
    }
    
    return _not(uint32_t);
}

- (void) clear {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return;
        
        pkgProblemResolver *resolver = [database_ resolver];
        resolver->Clear(iterator_);
        
        pkgCacheFile &cache([database_ cache]);
        cache->SetReInstall(iterator_, false);
        cache->MarkKeep(iterator_, false);
    } }

- (void) install {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return;
        
        pkgProblemResolver *resolver = [database_ resolver];
        resolver->Clear(iterator_);
        resolver->Protect(iterator_);
        
        pkgCacheFile &cache([database_ cache]);
        cache->SetCandidateVersion(version_);
        cache->SetReInstall(iterator_, false);
        cache->MarkInstall(iterator_, false);
        
        pkgDepCache::StateCache &state((*cache)[iterator_]);
        if (!state.Install())
            cache->SetReInstall(iterator_, true);
    } }

- (void) remove {
    @synchronized (database_) {
        if ([database_ era] != era_ || file_.end())
            return;
        
        pkgProblemResolver *resolver = [database_ resolver];
        resolver->Clear(iterator_);
        resolver->Remove(iterator_);
        resolver->Protect(iterator_);
        
        pkgCacheFile &cache([database_ cache]);
        cache->SetReInstall(iterator_, false);
        cache->MarkDelete(iterator_, true);
    } }

@end

CYString &(*PackageName)(Package *self, SEL sel);

//
//  MethodDeclarationSpacing.cpp
//  CustomLintingRules
//
//  Created by John Coates on 8/21/17.
//  Copyright © 2017 Limitless. All rights reserved.
//

#include "oclint/AbstractASTVisitorRule.h"
#include "oclint/RuleSet.h"
#include "oclint/util/StdUtil.h"
#include "clang/Lex/Lexer.h"

#include <iostream>

using namespace std;
using namespace clang;
using namespace oclint;

class MethodDeclarationSpacing : public AbstractASTVisitorRule<MethodDeclarationSpacing> {
public:
    virtual const string name() const override {
        return "Bad spacing on method declaration";
    }
    
    virtual const string identifier() const override
    {
        return "MethodDeclarationSpacing";
    }
    
    virtual int priority() const override
    {
        return 3;
    }
    
    virtual const string category() const override
    {
        return "style";
    }
    
    virtual unsigned int supportedLanguages() const override {
        return LANG_OBJC;
    }
    
    bool VisitObjCMethodDecl(ObjCMethodDecl *declaration) {
        string header = declarationHeader(declaration);
        
        if (declaration->isInstanceMethod()) {
            auto scopeSpacing = header.find("- (");
            if (scopeSpacing == string::npos) {
                addViolation(declaration, this);
            }
        } else {
            auto scopeSpacing = header.find("+ (");
            if (scopeSpacing == string::npos) {
                addViolation(declaration, this);
            }
        }
        
        auto start = declaration->getLocation();
        auto selectorStart = declaration->getSelectorStartLoc();
        
//        cout << header << endl;
        string beforeSelector = stringFromLocation(start, selectorStart);
        
        if (hasSuffix(beforeSelector, " ")) {
            addViolation(declaration, this);
        }
        
        return true;
    }
    
    private:
    
    string declarationHeader(ObjCMethodDecl *declaration) {
        SourceRange range = declaration->getSourceRange();
        auto begin = range.getBegin();
        auto end = declaration->getDeclaratorEndLoc();
        return stringFromLocation(begin, end);
    }
    
    string declarationWithBody(ObjCMethodDecl *declaration) {
        SourceRange range = declaration->getSourceRange();
        auto begin = range.getBegin();
        auto end = range.getEnd();
        return stringFromLocation(begin, end);
    }
    
    // includeEndToken includes { at the end of a header for example
    string stringFromLocation(SourceLocation rawBegin, SourceLocation rawEnd,
                              bool includeEndToken = false) {
        const SourceManager &manager = _carrier->getSourceManager();
        auto begin = manager.getSpellingLoc(rawBegin);
        auto end = manager.getSpellingLoc(rawEnd);
//        auto begin = rawBegin;
//        auto end = rawEnd;
        if (begin.isInvalid() || end.isInvalid()) {
            return "";
        }
        
        auto size = manager.getDecomposedLoc(end).second - manager.getDecomposedLoc(begin).second;
        if (includeEndToken) {
            const auto &langOpts = _carrier->getASTContext()->getLangOpts();
            size += clang::Lexer::MeasureTokenLength(end, manager, langOpts);
        }
        
        
        bool invalid = false;
        const char *data = manager.getCharacterData(begin, &invalid);
        if (invalid) {
            cout << "invalid!" << endl;
            return "";
        }
        
        string decValue = std::string(data, size);
        return decValue;
    }
    
    inline bool hasSuffix(std::string const & value, std::string const & suffix) {
        if (suffix.size() > value.size()) {
            return false;
        }
        return std::equal(suffix.rbegin(), suffix.rend(), value.rbegin());
    }
};

static RuleSet rules(new MethodDeclarationSpacing());

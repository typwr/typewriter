//
//  Analyzer.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/20.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

typealias MemberVariableToken = (Comments?, Type, Variable, Type?, Variable?, Nullable, Annotation?)
typealias FlattenToken = (Variable, String)

enum AnalysisOptionType: String {
    case comment = "comment"
    case immutable = "immutable"
    case constructOnly = "constructOnly"
    case specialIncludeSuffix = "specialIncludeSuffix"
    case initializerPreprocess = "initializerPreprocess"
    case unidirectionDataflow = "unidirectionDataflow"
}

typealias AnalysisOptions = [AnalysisOptionType: String]
typealias Hierarchy = SubTree

class Analyzer {
    fileprivate var options: AnalysisOptions
    fileprivate var memberVariableToken: [MemberVariableToken]
    fileprivate var flattenToken: [FlattenToken]?
    fileprivate var cachedHierachy: [Hierarchy]?
    
    init(options: AnalysisOptions,
         memberVariableToken: [MemberVariableToken],
         flattenToken: [FlattenToken]?) {
        self.options = options
        self.memberVariableToken = memberVariableToken
        self.flattenToken = flattenToken
    }
    
    func containOption(optionType: AnalysisOptionType) -> String? {
        return options[optionType]
    }
    
    func memberVariableTokenList() -> [MemberVariableToken] {
        return memberVariableToken
    }
    
    func analysisOptions() -> AnalysisOptions {
        return options
    }
    
    func isContainFlattenMemberVariable() -> Bool {
        return flattenToken != nil
    }
    
    func memberVariableHierarchySeparator() -> String {
        return "."
    }
    
    func memberVariableRootPlaceHolder() -> String {
        return "$"
    }
    
    func referenceFreeHierachy() -> [Hierarchy] {
        let hierarchy = memberVariableHierarchy()
        var simpleTable = [String: String]()
        
        hierarchy.forEach { (element) in
            simpleTable[element.1] = element.1
        }
        
        return hierarchy
            .map { (element) -> Hierarchy in
            return (element.0, element.1, element.2.filter({ (child) -> Bool in
                return simpleTable[child] == nil
            }))
            }
    }
    
    func memberVariableHierarchy() -> [Hierarchy] {
        if let cachedHierachy = cachedHierachy {
            return cachedHierachy
        }
        
        let path = mergeMemberVariablePath(memberVariable: memberVariableToken,
                                           flatten: flattenToken,
                                           inRewritten: true,
                                           needPlain: true).map{$0.1}
        let trie = Trie(separator: memberVariableHierarchySeparator(), rootValue: memberVariableRootPlaceHolder())
        path.forEach{trie.put(path: $0)}
        
        if let subtree = trie.dumpSubTree() {
            cachedHierachy = subtree
            return subtree
        }
        
        cachedHierachy = [(nil, memberVariableRootPlaceHolder(), memberVariableToken.map{$0.4 ?? $0.2})]
        return cachedHierachy!
    }
    
    func flattenMemberVariablePath() -> [(Variable, String)] {
        return mergeMemberVariablePath(memberVariable: memberVariableToken,
                                       flatten: flattenToken,
                                       inRewritten: false,
                                       needPlain: false)
    }
    
    fileprivate func mergeMemberVariablePath(memberVariable: [MemberVariableToken],
                                             flatten: [FlattenToken]?,
                                             inRewritten: Bool,
                                             needPlain: Bool) -> [(Variable, String)] {
        
        var res = [(Variable, String)]()
        if var flatten = flatten {
            memberVariable.forEach { (element) in
                let variable = element.4 ?? element.2
                if flatten.count > 0  && flatten.first!.0 == variable {
                    let nested = "\(flatten.first!.1)\(memberVariableHierarchySeparator())\(inRewritten ? flatten.first!.0 : element.2)"
                    res.append((variable, nested))
                    flatten.removeFirst()
                } else if needPlain {
                    res.append((variable, (inRewritten ? variable : element.2)))
                }
            }
        } else if needPlain {
            memberVariable.forEach({ (element) in
                let variable = element.4 ?? element.2
                res.append((variable, (inRewritten ? variable : element.2)))
            })
        }
        
        return res
    }
}

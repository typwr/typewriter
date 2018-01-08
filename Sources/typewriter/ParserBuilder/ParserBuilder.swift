//
//  ParserBuilder.swift
//  typewriter
//
//  Created by mrriddler on 2017/8/25.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

typealias RewrittenToken = (Variable, Type?, Variable?)

fileprivate enum SyntaxToken: String {
    case separator = ","
    case macroSeparator = "\\"
    case oneToOne = "="
    case annotaionLeftExpansion = "("
    case annotationRightExpansion = ")"
    case oneToManyLeftExpansion = "{"
    case oneToManyRightExpansion = "}"
}

struct Lexer {
    static func scanExpansion(leftExpansion: String, rightExpansion: String, src: String) -> String? {
        if src.hasPrefix(leftExpansion) && src.hasSuffix(rightExpansion) {
            let leftExpansionBound = src.range(of: leftExpansion)
            let rightExpansionBound = src.range(of: rightExpansion, options: .backwards)
            return String(src[leftExpansionBound!.upperBound ..< rightExpansionBound!.lowerBound])
        }
        return nil
    }
    
    static func scanOneToOne(prefix: String, src: String) -> String? {
        if src.hasPrefix(prefix) {
            let prefixBound = src.range(of: prefix)
            let prefixFree = String(src[prefixBound!.upperBound...]).trimmingLeftEndWhitespaces()
            if prefixFree.hasPrefix(SyntaxToken.oneToOne.rawValue) {
                let oneToOneBounds = prefixFree.range(of: SyntaxToken.oneToOne.rawValue)
                return String(prefixFree[oneToOneBounds!.upperBound...]).trimmingLeftEndWhitespaces()
            }
        }
        
        return nil
    }
    
    static func scanOneToMany(prefix: String, src: String) -> [String]? {
        if src.hasPrefix(prefix) {
            let prefixBound = src.range(of: prefix)
            let prefixFree = String(src[prefixBound!.upperBound...]).trimmingLeftEndWhitespaces()
            if prefixFree.hasPrefix(SyntaxToken.oneToOne.rawValue) {
                let oneToOneBounds = prefixFree.range(of: SyntaxToken.oneToOne.rawValue)
                let oneToOneFree = String(prefixFree[oneToOneBounds!.upperBound...]).trimmingLeftEndWhitespaces()
                if oneToOneFree.hasPrefix(SyntaxToken.oneToManyLeftExpansion.rawValue) && oneToOneFree.hasSuffix(SyntaxToken.oneToManyRightExpansion.rawValue) {
                    let oneToManyLeft = oneToOneFree.range(of: SyntaxToken.oneToManyLeftExpansion.rawValue)
                    let oneToManyRight = oneToOneFree.range(of: SyntaxToken.oneToManyRightExpansion.rawValue, options: .backwards)
                    let oneToManyExpansionFree = String(oneToOneFree[oneToManyLeft!.upperBound..<oneToManyRight!.lowerBound])
                    
                    var matchStack = [String]()
                    var separatedOneToMany = [String]()
                    var pre = -1
                    var separatorLength = 1
                    if oneToManyExpansionFree.range(of: SyntaxToken.macroSeparator.rawValue) != nil {
                        separatorLength = 2
                        pre = -2
                    }
                    
                    for (cur, element) in oneToManyExpansionFree.enumerated() {
                        if String(element) == SyntaxToken.annotaionLeftExpansion.rawValue ||
                             String(element) == SyntaxToken.oneToManyLeftExpansion.rawValue {
                            matchStack.append(String(element))
                        } else if String(element) == SyntaxToken.annotationRightExpansion.rawValue ||
                            String(element) == SyntaxToken.oneToManyRightExpansion.rawValue {
                            _ = matchStack.popLast()
                        } else if matchStack.first == nil && String(element) == SyntaxToken.separator.rawValue {
                            let preIdx = oneToManyExpansionFree.index(oneToManyExpansionFree.startIndex, offsetBy: pre + separatorLength)
                            let curIdx = oneToManyExpansionFree.index(oneToManyExpansionFree.startIndex, offsetBy: cur)
                            separatedOneToMany.append(String(oneToManyExpansionFree[preIdx ..< curIdx]))
                            pre = cur
                        }
                    }
                    
                    let preIdx = oneToManyExpansionFree.index(oneToManyExpansionFree.startIndex, offsetBy: pre + separatorLength)
                    let curIdx = oneToManyExpansionFree.endIndex
                    separatedOneToMany.append(String(oneToManyExpansionFree[preIdx ..< curIdx]))
                    
                    return separatedOneToMany
                }
            }
        }
        
        if let oneToOne = scanOneToOne(prefix: prefix, src: src) {
            return [oneToOne]
        }
        
        return nil
    }
}

fileprivate enum RuleToken: String {
    case generate = "generate"
    case inherit = "inherit"
    case implement = "implement"
    case immutable = "immutable"
    case constructOnly = "constructOnly"
    case commentOut = "commentOut"
    case specialIncludeSuffix = "specialIncludeSuffix"
    case initializerPreprocess = "initializerPreprocess"
    case unidirectionDataflow = "unidirectionDataflow"
    case filter = "filter"
    case predicateFilter = "predicateFilter"
    case rewritten = "rewritten"
}

fileprivate enum AnnotationToken: String {
    case ObjC = "#pragma Typewriter("
    case Swift = "@available(*, message: \"Typewriter("
    case Java = "@Typewriter("
    
    static func fromDescribeFormat(describeFormat: DescribeFormat) -> AnnotationToken? {
        switch describeFormat {
        case .GPPLObjC:
            return AnnotationToken.ObjC
        case .GPPLJava:
            return AnnotationToken.Java
        default:
            return nil
        }
    }
    
    static func extractIfNeeded(describeFormat: DescribeFormat, input: inout String) -> Bool {
        var preprocess = input
        if preprocess.hasSuffix(SyntaxToken.separator.rawValue) {
            preprocess = String(input[..<input.index(before: input.endIndex)])
        }
        
        switch describeFormat {
        case .GPPLObjC:
            if let expansionFree = Lexer.scanExpansion(leftExpansion: AnnotationToken.ObjC.rawValue,
                                                                     rightExpansion: SyntaxToken.annotationRightExpansion.rawValue,
                                                                     src: preprocess) {
                input = expansionFree
                return true
            } else if let expansionFree = Lexer.scanExpansion(leftExpansion:AnnotationToken.ObjC.rawValue.replacingOccurrences(of: " ", with: ""),
                                                  rightExpansion:SyntaxToken.annotationRightExpansion.rawValue,
                                                  src: preprocess) {
                input = expansionFree
                return true
            }
            
            return false
        case .GPPLJava:
            if let expansionFree = Lexer.scanExpansion(leftExpansion: AnnotationToken.Java.rawValue,
                                                                    rightExpansion: SyntaxToken.annotationRightExpansion.rawValue,
                                                                    src: preprocess) {
                input = expansionFree
                return true
            }
            
            return false
        default:
            return false
        }
    }
}

struct ParserContext {
    enum MatchState {
        case continuez
        case rewritten(context: String)
        
        func scan(describeFormat: DescribeFormat, src: inout String) -> MatchState {
            let whiteSpaceFree = src.replacingOccurrences(of: " ", with: "")
            switch self {
            case .continuez:
                if let annotationToken = AnnotationToken.fromDescribeFormat(describeFormat: describeFormat), whiteSpaceFree.hasPrefix("\(annotationToken.rawValue.replacingOccurrences(of: " ", with: ""))\(RuleToken.rewritten.rawValue)\(SyntaxToken.oneToOne.rawValue)") {
                    if whiteSpaceFree.range(of: "}", options: .backwards) != nil || whiteSpaceFree.hasSuffix("))") {
                        return MatchState.continuez
                    } else {
                        return MatchState.rewritten(context: whiteSpaceFree)
                    }
                } else {
                    return MatchState.continuez
                }
            case .rewritten(let context):
                if whiteSpaceFree.range(of: "}", options: .backwards) != nil {
                    src = context + whiteSpaceFree
                    return MatchState.continuez
                } else {
                    return MatchState.rewritten(context: context + whiteSpaceFree)
                }
            }
        }
    }
    
    var state: MatchState
    var path: String
    var srcName: String
    var srcInheriting: String?
    var srcImplement: [String]?
    var desName: String
    var desInheriting: String?
    
    var options: AnalysisOptions
    var rewrittenMap: [Variable: RewrittenToken]
    var memberVariableMap: [Variable: MemberVariableToken]
    var memberVariableQueue: [Variable]
    var memberVariableFilter: [Variable]
    var memberVariablePredicateFilter: String
    
    var isCollecting: Bool
    var commentQueue: [String]
    
    init(path: String) {
        self.state = .continuez
        self.path = path
        self.srcName = String()
        self.desName = String()
        
        self.options = AnalysisOptions()
        self.rewrittenMap = [Variable: RewrittenToken]()
        self.memberVariableMap = [Variable: MemberVariableToken]()
        self.memberVariableQueue = [Variable]()
        self.memberVariableFilter = [Variable]()
        self.memberVariablePredicateFilter = String()
        
        self.isCollecting = false
        self.commentQueue = [String]()
        
        self.options[AnalysisOptionType.comment] = AnalysisOptionType.comment.rawValue
    }
}

protocol ParserBuilder {
    static func inputFormat() -> DescribeFormat
    static func build(file: (String, [String])) -> IR
    static func constructLanguage(context: inout ParserContext, input: String)
    static func constructComment(context: inout ParserContext, input: String)
    static func constructRule(context: inout ParserContext, input: String)
    static func getResult(context: ParserContext) -> IR
}

extension ParserBuilder {
    static func build(file: (String, [String])) -> IR {
        var context = ParserContext(path: file.0)
        
        file.1.forEach { (line) in
            constructLanguage(context: &context, input: line)
            constructComment(context: &context, input: line)
            constructRule(context: &context, input: line)
        }
        
        return getResult(context: context)
    }
    
    static func constructComment(context: inout ParserContext, input: String) {
        if context.isCollecting == true {
            accmulateComment(input: input, commentQueue: &context.commentQueue)
        }
    }
    
    static func constructRule(context: inout ParserContext, input: String) {
        var next = stripSymbol(src: input)
        if parseState(context: &context, next: &next) {
            if parseAnnotation(next: &next) {
                parseRule(context: &context, next: next)
            }
        }
    }
    
    static func getResult(context: ParserContext) -> IR {
        return IR.translationToIR(path: context.path,
                                  inputFormat: inputFormat(),
                                  srcName: context.srcName,
                                  srcInheriting: context.srcInheriting,
                                  srcImplement: context.srcImplement,
                                  desName: context.desName,
                                  desInheriting: context.desInheriting,
                                  memberVariableToken: filter(filter: context.memberVariableFilter,
                                                              predicateFilter: context.memberVariablePredicateFilter,
                                                              memberVariableToken: merge(rewrittenMap: context.rewrittenMap,
                                                                                         memberVariableMap: context.memberVariableMap,
                                                                                         memberVariableQueue: context.memberVariableQueue)),
                                  options: context.options,
                                  flattenToken: nil)
    }
    
    static func parseState(context: inout ParserContext, next: inout String) -> Bool {
        context.state = context.state.scan(describeFormat: inputFormat(), src: &next)
        switch context.state {
        case .continuez:
            return true
        case .rewritten:
            return false
        }
    }
    
    static func parseAnnotation(next: inout String) -> Bool {
        return AnnotationToken.extractIfNeeded(describeFormat: inputFormat(), input: &next)
    }
    
    static func parseRule(context: inout ParserContext, next: String) {
        let interpreters: [RuleInterpretable] = [GenerateInterpreter(),
                                                 InheritInterpreter(),
                                                 ImplementInterpreter(),
                                                 OptionInterpreter(),
                                                 IncludeSuffixInterpreter(),
                                                 FilterInterpreter(),
                                                 PredicateFilterInterpreter(),
                                                 RewrittenInterpreter()]
        for interpreter in interpreters {
            if interpreter.interpreter(context: &context, input: next) {
                break
            }
        }
    }
    
    static func accmulateComment(input: String, commentQueue: inout [String]) {
        if input.hasPrefix("*") {
            let commentSymbolFree = String(input[input.index(after: input.startIndex)...])
            let leftWhiteSpaceFree = commentSymbolFree.trimmingLeftEndWhitespaces()
            commentQueue.append(leftWhiteSpaceFree)
        }
        
        if input.hasPrefix("//") {
            let commentSymbolFree = String(input[input.index(after: input.index(after: input.startIndex))...])
            let leftWhiteSpaceFree = commentSymbolFree.trimmingLeftEndWhitespaces()
            commentQueue.append(leftWhiteSpaceFree)
        }
        
        if input.hasPrefix("///") {
            let commentSymbolFree = String(input[input.index(after: input.index(after: input.index(after: input.startIndex)))...])
            let leftWhiteSpaceFree = commentSymbolFree.trimmingLeftEndWhitespaces()
            commentQueue.append(leftWhiteSpaceFree)
        }
    }
    
    static func queryComment(commentQueue: inout [String]) -> [String]? {
        if commentQueue.count <= 0 {
            return nil
        }
        
        let res = Array(commentQueue)
        commentQueue.removeAll()
        return res
    }
    
    static func filter(filter: [Variable],
                       predicateFilter: String,
                       memberVariableToken: [MemberVariableToken]) -> [MemberVariableToken] {
        return memberVariableToken
            .filter{ !filter.contains($0.2) }
            .filter({ (memberVariable) -> Bool in
                if predicateFilter.isEmpty {
                    return true
                } else {
                    if let separator = predicateFilter.range(of: SyntaxToken.separator.rawValue) {
                        let format = String(predicateFilter[..<separator.lowerBound])
                        let param = String(predicateFilter[separator.upperBound...])
                        let paramArr = param.components(separatedBy: SyntaxToken.separator.rawValue).map{$0.trimmingCharacters(in: .whitespaces)};
                        if format.range(of: "%@") == nil {
                            print("Error: \(format) is not a valid predicateFilter")
                            exit(1)
                        }
                        let predicate = NSPredicate(format: format, argumentArray: paramArr)
                        return !predicate.evaluate(with: memberVariable.2)
                    } else {
                        let predicate = NSPredicate(format: predicateFilter)
                        return !predicate.evaluate(with: memberVariable.2)
                    }
                }
            })
    }
    
    static func merge(rewrittenMap: [Variable: RewrittenToken],
                      memberVariableMap: [Variable: MemberVariableToken],
                      memberVariableQueue: [Variable]) -> [MemberVariableToken] {
        var result = [MemberVariableToken]()
        var mergeMap = memberVariableMap
        
        rewrittenMap.forEach { (rewritten) in
            if memberVariableMap[rewritten.key] != nil {
                mergeMap[rewritten.key] = (memberVariableMap[rewritten.key]!.0, memberVariableMap[rewritten.key]!.1, memberVariableMap[rewritten.key]!.2, rewritten.value.2, rewritten.value.1, memberVariableMap[rewritten.key]!.5, memberVariableMap[rewritten.key]!.6)
            }
        }
        
        for memberVariable in memberVariableQueue {
            result.append(mergeMap[memberVariable]!)
        }
        
        return result
    }
    
    static func stripSymbol(src: String) -> String {
        return src.replacingOccurrences(of: "\"", with: "")
    }
    
    static func filterProto(src: String) -> Bool {
        guard !src.hasSuffix("Root") &&
            !src.hasSuffix("Builder") &&
            !src.hasSuffix("Adapter") &&
            src.range(of: "_") == nil else {
            return false
        }
        
        return true
    }
}

fileprivate protocol RuleInterpretable {
    var rule: RuleToken { get }
    func interpreter(context: inout ParserContext, input: String) -> Bool
}

extension RuleInterpretable {
    fileprivate static func parseOneToOneRule(rule: RuleToken, src: String) -> String? {
        switch rule {
        case .generate, .inherit, .specialIncludeSuffix, .predicateFilter:
            return Lexer.scanOneToOne(prefix: rule.rawValue, src: src)
        default:
            return nil
        }
    }
    
    fileprivate static func parseOneToManyRule(rule: RuleToken, src: String) -> [String]? {
        switch rule {
        case .filter, .implement:
            return Lexer.scanOneToMany(prefix: rule.rawValue, src: src)
        default:
            return nil
        }
    }
    
    fileprivate static func parseRewritten(prefix: String, src: String) -> [RewrittenToken]? {
        let whitespacesFree = src.trimmingCharacters(in: .whitespaces)
        var tokens: [RewrittenToken]?
        
        if let oneToMany = Lexer.scanOneToMany(prefix: prefix, src: whitespacesFree) {
            oneToMany.forEach({ (element) in
                if let annotationFree = Lexer.scanExpansion(
                    leftExpansion: "@Rewritten\(SyntaxToken.annotaionLeftExpansion.rawValue)",
                    rightExpansion: SyntaxToken.annotationRightExpansion.rawValue,
                    src: element) {
                    if let token = parseRewrittenAnnotation(src: annotationFree) {
                        if tokens == nil {
                            tokens = [RewrittenToken]()
                        }
                        tokens!.append(token)
                    }
                } else if let annotationFree = Lexer.scanExpansion(
                    leftExpansion: "Rewritten\(SyntaxToken.annotaionLeftExpansion.rawValue)",
                    rightExpansion: SyntaxToken.annotationRightExpansion.rawValue,
                    src: element) {
                    if let token = parseRewrittenAnnotation(src: annotationFree) {
                        if tokens == nil {
                            tokens = [RewrittenToken]()
                        }
                        tokens!.append(token)
                    }
                }
                
            })
        }
        
        return tokens
    }
    
    fileprivate static func parseRewrittenAnnotation(src: String) -> RewrittenToken? {
        var srcName: Variable?
        var desName: Variable?
        var desType: Type?
        
        let separated = src.components(separatedBy: SyntaxToken.separator.rawValue)
        separated.forEach({ (element) in
            let leftEndWhitespaceFree = element.trimmingLeftEndWhitespaces()
        
            if let originalName = Lexer.scanOneToOne(prefix: "on", src: leftEndWhitespaceFree) {
                srcName = originalName
            }
            
            if let rewrittenName = Lexer.scanOneToOne(prefix: "name", src: leftEndWhitespaceFree) {
                desName = rewrittenName
            }
            
            if let rewrittenType = Lexer.scanOneToOne(prefix: "type", src: leftEndWhitespaceFree) {
                desType = rewrittenType
            }
        })
        
        if srcName != nil && (desName != nil || desType != nil) {
            return (srcName!, desName, desType)
        }
        
        return nil
    }
}

fileprivate struct GenerateInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.generate
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            if let token = GenerateInterpreter.parseOneToOneRule(rule: rule, src: input) {
                context.desName = token
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct InheritInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.inherit
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            if let token = InheritInterpreter.parseOneToOneRule(rule: rule, src: input) {
                context.desInheriting = token
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct ImplementInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.implement
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            if let token = ImplementInterpreter.parseOneToManyRule(rule: rule, src: input) {
                context.srcImplement = token
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct OptionInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.immutable
        }
    }
    
    func interpreter(context: inout ParserContext, input: String) -> Bool {
        var findAtLeastOne = false
        let interpreters: [RuleInterpretable] = [ImmutableInterpreter(),
                                                 ConstructOnlyInterpreter(),
                                                 CommentOutInterpreter(),
                                                 InitializerInterpreter(),
                                                 UnidirectionDataflowInterpreter()]
        
        for interpreter in interpreters {
            if interpreter.interpreter(context: &context, input: input) {
                findAtLeastOne = true
            }
        }
        
        return findAtLeastOne
    }
}

fileprivate struct ImmutableInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.immutable
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            context.options[AnalysisOptionType.immutable] = AnalysisOptionType.immutable.rawValue
            
            return true
        }
        
        return false
    }
}

fileprivate struct ConstructOnlyInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.constructOnly
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            context.options[AnalysisOptionType.constructOnly] = AnalysisOptionType.constructOnly.rawValue
            
            return true
        }
        
        return false
    }
}

fileprivate struct CommentOutInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.commentOut
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            context.options.removeValue(forKey: AnalysisOptionType.comment)
            
            return true
        }
        
        return false
    }
}

fileprivate struct InitializerInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.initializerPreprocess
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            context.options[AnalysisOptionType.initializerPreprocess] = AnalysisOptionType.initializerPreprocess.rawValue
            
            return true
        }
        
        return false
    }
}

fileprivate struct UnidirectionDataflowInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.unidirectionDataflow
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            context.options[AnalysisOptionType.unidirectionDataflow] = AnalysisOptionType.unidirectionDataflow.rawValue
            
            return true
        }
        
        return false
    }
}

fileprivate struct IncludeSuffixInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.specialIncludeSuffix
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            if let token = IncludeSuffixInterpreter.parseOneToOneRule(rule: rule, src: input) {
                context.options[AnalysisOptionType.specialIncludeSuffix] = token.replacingOccurrences(of: " ", with: "")
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct FilterInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.filter
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            if let token = FilterInterpreter.parseOneToManyRule(rule: rule, src: input) {
                context.memberVariableFilter = token
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct PredicateFilterInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.predicateFilter
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            if let token = PredicateFilterInterpreter.parseOneToOneRule(rule: rule, src: input) {
                context.memberVariablePredicateFilter = token
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct RewrittenInterpreter: RuleInterpretable {
    fileprivate var rule: RuleToken {
        get {
            return RuleToken.rewritten
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.range(of: rule.rawValue) != nil {
            if let tokens = RewrittenInterpreter.parseRewritten(prefix: rule.rawValue, src: input) {
                tokens.forEach{context.rewrittenMap[$0.0] = $0}
            }
            
            return true
        }
        
        return false
    }
}

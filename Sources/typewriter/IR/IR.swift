//
//  IR.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/5.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

typealias Comments = [String]
typealias Type = String
typealias Variable = String

enum Nullable: String {
    case required = "required"
    case almost = "almost"
    case optional = "optional"
}

enum RewrittenFormat {
    case prototype
    case json
    
    static func formatFrom(describeFormat: DescribeFormat) -> RewrittenFormat {
        switch describeFormat {
        case .GPPLObjC:
            return RewrittenFormat.prototype
        case .GPPLJava:
            return RewrittenFormat.prototype
        case .JSON:
            return RewrittenFormat.json
        }
    }
}

typealias Annotation = [String]
typealias Rewritten = (IRType?, Variable?, RewrittenFormat?)
typealias MemberVariable = (Comments?, IRType, Variable, Rewritten?, Nullable, Annotation?)

func finalVariable(memberVariable: MemberVariable) -> Variable {
    return memberVariable.3?.1 ?? memberVariable.2
}

func finalType(memberVariable: MemberVariable) -> IRType {
    return memberVariable.3?.0 ?? memberVariable.1
}

enum GenerateModuleType {
    case prototypeInitializer
    case prototypeInitializerPreprocess
    case jsonInitializer
    case jsonInitializerPreprocess
    case equality
    case print
    case archive
    case copy
    case hash
    case unidirectionalDataflow
    case mutableVersion
}

typealias GenerateModules = [GenerateModuleType]

indirect enum IRType {
    case float
    case double
    case uint32
    case uint64
    case sint32
    case sint64
    case bool
    case string
    case date
    case array(type: IRType?)
    case map(keyType: IRType?, valueType: IRType?)
    case ambiguous(type: Type)
    case any
    
    func getNestedType() -> Type? {
        switch self {
        case .ambiguous(let type):
            return type
        case .array(let type):
            if let type = type {
                return type.getNestedType()
            } else {
                return nil
            }
        case .map(_, let valueType):
            if let valueType = valueType {
                return valueType.getNestedType()
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    func setNestedType(desType: Type) -> IRType {
        switch self {
        case .ambiguous(_):
            return .ambiguous(type: desType)
        case .array(let type):
            if let type = type {
                return .array(type: type.setNestedType(desType: desType))
            } else {
                return .array(type: .ambiguous(type: desType))
            }
        case .map(let keyType, let valueType):
            if let keyType = keyType, let valueType = valueType {
                return .map(keyType: keyType, valueType: valueType.setNestedType(desType: desType))
            } else {
                return .map(keyType: .string, valueType: .ambiguous(type: desType))
            }
        default:
            return self
        }
    }
    
    func getNestedIRType() -> IRType? {
        switch self {
        case .ambiguous:
            return self
        case .array(let type):
            if let type = type {
                if let nestedType = type.getNestedIRType() {
                    return nestedType
                } else {
                    return nil
                }
            } else {
                return nil
            }
        case .map(_, let valueType):
            if let valueType = valueType {
                if let nestedType = valueType.getNestedIRType() {
                    return nestedType
                } else {
                    return nil
                }
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    func setNestedIRType(desType: IRType) -> IRType {
        switch self {
        case .ambiguous(_):
            return desType
        case .array(let type):
            if let type = type {
                return .array(type: type.setNestedIRType(desType: desType))
            } else {
                return desType
            }
        case .map(let keyType, let valueType):
            if let keyType = keyType, let valueType = valueType {
                return .map(keyType: keyType, valueType: valueType.setNestedIRType(desType: desType))
            } else {
                return desType
            }
        default:
            return self
        }
    }
}

extension IRType: Equatable {
    public static func ==(lhs: IRType, rhs: IRType) -> Bool {
        switch (lhs, rhs) {
        case (.float, .float):
            return true
        case (.double, .double):
            return true
        case (.uint32, .uint32):
            return true
        case (.uint64, .uint64):
            return true
        case (.sint32, .sint32):
            return true
        case (.sint64, .sint64):
            return true
        case (.bool, .bool):
            return true
        case (.string, .string):
            return true
        case (.date, .date):
            return true
        case (.array, .array):
            return true
        case (.map, .map):
            return true
        case (.ambiguous, .ambiguous):
            return true
        case (.any, .any):
            return true
        default:
            return false
        }
    }
}

class IR {
    var path: String
    var inputFormat: DescribeFormat
    var srcName: String
    var srcInheriting: String?
    var srcImplement: [String]?
    var desName: String
    var desInheriting: String?
    var memberVariableList: [MemberVariable]!
    var generateModules: GenerateModules!
    var referenceMap: [Variable: String]!
    fileprivate var analyzer: Analyzer
    
    init(path: String,
         inputFormat: DescribeFormat,
         srcName: String,
         srcInheriting: String?,
         srcImplement: [String]?,
         desName: String,
         desInheriting: String?,
         memberVariableList: [MemberVariable]?,
         generateModules: GenerateModules?,
         referenceMap: [Variable: String]?,
         analyzer: Analyzer) {
        self.path = path
        self.inputFormat = inputFormat
        self.srcName = srcName
        self.srcInheriting = srcInheriting
        self.srcImplement = srcImplement
        self.desName = desName
        self.desInheriting = desInheriting
        self.memberVariableList = memberVariableList
        self.generateModules = generateModules
        self.referenceMap = referenceMap
        self.analyzer = analyzer
    }
    
    class func translationToIR(path: String,
                               inputFormat: DescribeFormat,
                               srcName: String,
                               srcInheriting: String?,
                               srcImplement: [String]?,
                               desName: String,
                               desInheriting: String?,
                               memberVariableToken: [MemberVariableToken],
                               options: AnalysisOptions,
                               flattenToken: [FlattenToken]?) -> IR {
        var switchRewrittenToken = memberVariableToken
        if inputFormat == .JSON {
            switchRewrittenToken = switchRewrittenToken
                .map{(varToken: MemberVariableToken) -> MemberVariableToken in
                    return (varToken.0,
                            varToken.1,
                            varToken.4 ?? varToken.2,
                            varToken.3,
                            (varToken.4 != nil ? varToken.2 : nil),
                            varToken.5,
                            varToken.6)}
        }
        
        let analyzer = Analyzer(options: options,
                                memberVariableToken: switchRewrittenToken,
                                flattenToken: flattenToken)
        let ir = IR(path: path,
                    inputFormat: inputFormat,
                    srcName: srcName,
                    srcInheriting: srcInheriting,
                    srcImplement: srcImplement,
                    desName: desName,
                    desInheriting: desInheriting,
                    memberVariableList: nil,
                    generateModules: nil,
                    referenceMap: nil,
                    analyzer: analyzer)
        return ir
    }
    
    func deduce() {
        switch inputFormat {
        case .GPPLObjC:
            memberVariableList = DeducePrototypeStrategy.deduceTokenList(
                src: path,
                comment: analyzer.containOption(optionType: .comment) != nil,
                typeConvertor: typeConvertor(forLanguage: .ObjC),
                tokenList: analyzer.memberVariableTokenList())
            generateModules = DeducePrototypeStrategy.deduceOptions(options: analyzer.analysisOptions())
            referenceMap = DeducePrototypeStrategy.deduceReferenceMap(typeConvertor: typeConvertor(forLanguage: .ObjC),
                                                                      tokenList: analyzer.memberVariableTokenList())
        case .GPPLJava:
            memberVariableList = DeducePrototypeStrategy.deduceTokenList(
                src: path,
                comment: analyzer.containOption(optionType: .comment) != nil,
                typeConvertor: typeConvertor(forLanguage: .Java),
                tokenList: analyzer.memberVariableTokenList())
            generateModules = DeducePrototypeStrategy.deduceOptions(options: analyzer.analysisOptions())
            referenceMap = DeducePrototypeStrategy.deduceReferenceMap(typeConvertor: typeConvertor(forLanguage: .Java),
                                                                      tokenList: analyzer.memberVariableTokenList())
        case .JSON:
            memberVariableList = DeduceJSONStrategy.deduceTokenList(
                src: path,
                comment: analyzer.containOption(optionType: .comment) != nil,
                tokenList: analyzer.memberVariableTokenList())
            generateModules = DeduceJSONStrategy.deduceOptions(options: analyzer.analysisOptions())
            referenceMap = DeduceJSONStrategy.deduceReferenceMap(tokenList: analyzer.memberVariableTokenList())
        }
        
        if isModelUnique() {
            memberVariableList.insert((nil, .string, modelId(), nil, .optional, nil), at: 0);
        }
    }
    
    func containModule(type: GenerateModuleType) -> Bool {
        return generateModules.index(of: type) != nil
    }
    
    func isGenerateExtension() -> Bool {
        return (isModelUnique() ||
            containModule(type: .prototypeInitializerPreprocess) ||
            containModule(type: .jsonInitializerPreprocess))
    }
    
    func isModelUnique() -> Bool {
        return containModule(type: .unidirectionalDataflow)
    }
    
    func isMemberVariableReadOnly() -> Bool {
        return analyzer.containOption(optionType: .immutable) != nil || analyzer.containOption(optionType: .constructOnly) != nil
    }
    
    func isContainRewrittenName() -> Bool {
        for memberVariable in memberVariableList {
            if memberVariable.3?.1 != nil {
                return true
            }
        }
        
        return false
    }
    
    func isContainBuildInRewrittenType() -> Bool {
        return memberVariableList.contains(where: { element -> Bool in
            if let rewrittenType = element.3?.0 {
                switch (element.1, rewrittenType) {
                case (.string, .float):
                    return true
                case (.string, .double):
                    return true
                case (.string, .sint32):
                    return true
                case (.string, .sint64):
                    return true
                case (.string, .uint32):
                    return true
                case (.string, .uint64):
                    return true
                case (.string, .bool):
                    return true
                default:
                    break
                }
            }
            
            return false
        })
    }
    
    func isMemberVariableEnum(memberVariable: MemberVariable) -> Bool {
        if let rewrittenType = memberVariable.3?.0 {
            switch (memberVariable.1, rewrittenType) {
            case (.string, .ambiguous):
                if memberVariable.3?.2 != nil {
                    return false
                } else {
                    return true
                }
            default:
                break
            }
        }
        
        return false
    }
    
    func isContainEnum() -> Bool {
        return memberVariableList.contains{isMemberVariableEnum(memberVariable: $0)}
    }
    
    func findType(find: (IRType, IRType) -> Type?) -> [Type] {
        var res = [Type]()
        
        memberVariableList.forEach { (memberVariable: MemberVariable) in
            _ = memberVariable.3?.0
                .map{ (rewrittenType) in
                    switch (memberVariable.1, rewrittenType) {
                    case (.string, .ambiguous):
                        if !isMemberVariableEnum(memberVariable: memberVariable), let type = find(memberVariable.1, rewrittenType) {
                            res.append(type)
                        }
                    case (.ambiguous, .ambiguous),
                         (.array, .array),
                         (.map, .map):
                        if let type = find(memberVariable.1, rewrittenType) {
                            res.append(type)
                        }
                    default:
                        break
                    }
            }
        }
        
        return res
    }
    
    func makeMemberVariableMap() -> [Variable: MemberVariable] {
        var res = [Variable: MemberVariable]()
        for memberVariable in memberVariableList {
            res[finalVariable(memberVariable: memberVariable)] = memberVariable
        }
        
        return res
    }
    
    func makeRewrittenNameMap() -> [Variable: Variable] {
        var res = [Variable: Variable]()
        for memberVariable in memberVariableList {
            if let rewritten = memberVariable.3?.1 {
                res[rewritten] = memberVariable.2
            }
        }
        
        return res
    }
    
    func makeFlattenMap() -> [Variable: Variable] {
        var variableMap = [Variable: Variable]()
        let flattenPath = flattenMemberVariablePath()
        
        switch RewrittenFormat.formatFrom(describeFormat: inputFormat) {
        case .json:
            flattenPath.forEach({ (element) in
                variableMap[element.0] = element.1
            })
        default:
            break
        }
        
        return variableMap
    }
    
    func makeReferenceFlattenMap() -> [Variable: Variable] {
        var variableMap = [Variable: Variable]()

        memberVariableList.forEach { memberVariable in
            if let rewrittenFormat = memberVariable.3?.2, memberVariable.3?.0 != nil {
                switch rewrittenFormat {
                case .json:
                    let variable = finalVariable(memberVariable: memberVariable)
                    if let referenceIR = jumpToReferenceIR(variable: variable) {
                        let flattenMap = referenceIR.makeFlattenMap()
                        flattenMap.forEach({ element in
                            variableMap["\(variable)\(memberVariableHierarchySeparator())\(element.key)"] = "\(variable)\(memberVariableHierarchySeparator())\(element.value)"
                        })
                    }
                default:
                    break
                }
            }
        }
        
        return variableMap
    }
    
    func jumpToReferenceIR(variable: Variable) -> IR? {
        if let path = referenceMap[variable] {
            let referenceURL = URL(string: path, relativeTo: TranslationCache.sharedInstance.curDirectory)!
            return TranslationCache.sharedInstance.irs[referenceURL]
        }
        
        return nil
    }
    
    func specialIncludeSuffix() -> String? {
        return analyzer.containOption(optionType: .specialIncludeSuffix)
    }
    
    func modelId() -> String {
        return "objectId"
    }
}

extension IR {
    func isContainFlattenMemberVariable() -> Bool {
        return analyzer.isContainFlattenMemberVariable()
    }

    func memberVariableHierarchySeparator() -> String {
        return analyzer.memberVariableHierarchySeparator()
    }
    
    func memberVariableRootPlaceHolder() -> String {
        return analyzer.memberVariableRootPlaceHolder()
    }
    
    func memberVariableHierarchy() -> [Hierarchy] {
        return analyzer.memberVariableHierarchy()
    }
    
    func referenceFreeHierachy() -> [Hierarchy] {
        return analyzer.referenceFreeHierachy()
    }
            
    func flattenMemberVariablePath() -> [(Variable, String)] {
        return analyzer.flattenMemberVariablePath()
    }
}


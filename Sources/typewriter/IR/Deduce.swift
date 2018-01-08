//
//  Deduce.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/20.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

protocol DeduceStrategy {
    static func deduceTokenList(src: String,
                                comment: Bool,
                                typeConvertor: @escaping (Type) -> IRType,
                                tokenList: [MemberVariableToken]) -> [MemberVariable]
    static func deduceReferenceMap(typeConvertor: @escaping (Type) -> IRType,
                                   tokenList: [MemberVariableToken]) -> [Variable: String]
    static func deduceOptions(options: AnalysisOptions) -> GenerateModules
}

protocol TwoPhaseDeduceable {
    static func deduceMemberVariableList(memberVariableList: [MemberVariable]) -> [MemberVariable]
    static func deduceGenerateModules(generateModules: GenerateModules) -> GenerateModules
}

extension DeduceStrategy {
    fileprivate static func parseRefPath(reference: Type) -> String? {
        if let reference = Lexer.scanExpansion(leftExpansion: "$ref(",
                                                            rightExpansion: ")",
                                                            src: reference) {
            return reference
        } else {
            return nil
        }
    }

    fileprivate static func parseRef(src: String, reference: String?) -> IR? {
        if let reference = reference {
            return executeFrontEndParse(src: src, reference: reference)
        } else {
            return nil
        }
    }
    
    fileprivate static func rewrittenType(originalType: IRType, designedType: IRType) -> IRType? {
        switch (originalType, designedType) {
        case (.string, .ambiguous):
            return designedType
        case (.string, .float):
            return .float
        case (.string, .double):
            return .double
        case (.string, .uint32):
            return .uint32
        case (.string, .uint64):
            return .uint64
        case (.string, .sint32):
            return .sint32
        case (.string, .sint64):
            return .sint64
        case (.string, .bool):
            return .bool
        case (.ambiguous, .ambiguous):
            return designedType
        case (.array(let elementType), .ambiguous(_)):
            if let nestedType = elementType {
                return .array(type: rewrittenType(originalType:nestedType, designedType:designedType))
            } else {
                return .array(type: designedType)
            }
        case (.map(_, let valueType), .ambiguous(_)):
            if let nestedType = valueType {
                return .map(keyType: .string, valueType: rewrittenType(originalType: nestedType, designedType: designedType))
            } else {
                return .map(keyType: .string, valueType: designedType)
            }
        case (.any, .ambiguous):
            return designedType
        default:
            return nil
        }
    }
}

struct DeduceJSONStrategy: DeduceStrategy {
    static func deduceTokenList(src: String, comment: Bool, tokenList: [MemberVariableToken]) -> [MemberVariable] {
        return deduceTokenList(src: src, comment: comment, typeConvertor: typeConvertor(forLanguage: .ObjC), tokenList: tokenList)
    }
    
    static func deduceReferenceMap(tokenList: [MemberVariableToken]) -> [Variable : String] {
        return deduceReferenceMap(typeConvertor: typeConvertor(forLanguage: .ObjC), tokenList: tokenList)
    }
        
    static func deduceTokenList(src: String,
                                comment: Bool,
                                typeConvertor: @escaping (Type) -> IRType,
                                tokenList: [MemberVariableToken]) -> [MemberVariable] {
        return tokenList
            .map{(varToken: MemberVariableToken) -> MemberVariable in
                return ((comment ? varToken.0 : nil),
                        TypeToIRType(type: varToken.1),
                        varToken.2,
                        (varToken.3.map(TypeToIRType), varToken.4, nil),
                        varToken.5,
                        varToken.6)}
            .map{(memberVariable: MemberVariable) -> (MemberVariable) in
                return rewrittenRefInJSON(src: src, memberVariable: memberVariable)}
    }
    
    static func deduceReferenceMap(typeConvertor: @escaping (Type) -> IRType,
                                   tokenList: [MemberVariableToken]) -> [Variable : String] {
        return tokenList
            .map{(varToken: MemberVariableToken) -> MemberVariable in
                return (nil,
                        TypeToIRType(type: varToken.1),
                        varToken.2,
                        (varToken.3.map(TypeToIRType), varToken.4, nil),
                        varToken.5,
                        varToken.6)
            }
            .flatMap{(memberVariable: MemberVariable) -> (Variable, String)? in
                if let path = findRefPathInJSON(memberVariable: memberVariable) {
                    return (finalVariable(memberVariable: memberVariable), path)
                } else {
                    return nil
                }
            }
            .reduce([:], {
                var dic = $0
                dic[$1.0] = $1.1
                return dic
            })
    }
    
    static func deduceOptions(options: AnalysisOptions) -> GenerateModules {
        var res = GenerateModules()
        
        res.append(.jsonInitializer)
        if options[.initializerPreprocess] != nil {
            res.append(.jsonInitializerPreprocess)
        }
        
        if options[.immutable] != nil {
            res.append(.mutableVersion)
            res.append(.unidirectionalDataflow)
        } else if options[.unidirectionDataflow] != nil {
            res.append(.unidirectionalDataflow)
        }
        
        res.append(.archive)
        res.append(.copy)
        res.append(.equality)
        res.append(.print)
        res.append(.hash)
        
        return res
    }
    
    fileprivate static func rewrittenRefInJSON(src: String, memberVariable: MemberVariable) -> MemberVariable {
        if let path = findRefPathInJSON(memberVariable: memberVariable) {
            return parseIRIfNeededInJSON(src: src, path: path, memberVariable: memberVariable)
        } else if let rewrittenType = memberVariable.3?.0  {
            return (memberVariable.0,
                    rewrittenType,
                    memberVariable.2,
                    (memberVariable.1, memberVariable.3?.1, memberVariable.3?.2) ,
                    memberVariable.4,
                    memberVariable.5)
        }
        
        return memberVariable
    }
    
    fileprivate static func findRefPathInJSON(memberVariable: MemberVariable) -> String? {
        let finalType = memberVariable.3?.0 ?? memberVariable.1
        
        switch finalType {
        case .ambiguous(let type):
            return parseIRPathIfNeededInJSON(type: type)
        case .array, .map:
            if let nestedIRType = finalType.getNestedIRType() {
                switch nestedIRType {
                case .ambiguous(let type):
                    return parseIRPathIfNeededInJSON(type: type)
                default:
                    break
                }
            }
        default:
            break
        }
        
        return nil
    }
    
    fileprivate static func parseIRIfNeededInJSON(src: String,
                                                 path: String?,
                                                 memberVariable: MemberVariable) -> MemberVariable {
        if let ir = parseRef(src: src, reference: path) {
            let rewrittenFormat = RewrittenFormat.formatFrom(describeFormat: ir.inputFormat)
            switch rewrittenFormat {
            case .prototype:
                return (memberVariable.0,
                        memberVariable.1.setNestedIRType(desType: IRType.ambiguous(type: ir.srcName)),
                        memberVariable.2,
                        (memberVariable.1.setNestedIRType(desType: IRType.ambiguous(type: ir.desName)), memberVariable.3?.1, rewrittenFormat),
                        memberVariable.4,
                        memberVariable.5)
            case .json:
                return (memberVariable.0,
                        memberVariable.1.setNestedIRType(desType: IRType.string),
                        memberVariable.2,
                        (memberVariable.1.setNestedIRType(desType: IRType.ambiguous(type: ir.desName)), memberVariable.3?.1, rewrittenFormat),
                        memberVariable.4,
                        memberVariable.5)
            }
        }
        return memberVariable
    }
    
    fileprivate static func parseIRPathIfNeededInJSON(type: Type) -> String? {
        return parseRefPath(reference: type)
    }
}

struct DeducePrototypeStrategy: DeduceStrategy {
    static func deduceTokenList(src: String,
                                comment: Bool,
                                typeConvertor: @escaping (Type) -> IRType,
                                tokenList: [MemberVariableToken]) -> [MemberVariable] {
        return tokenList
            .map{(varToken: MemberVariableToken) -> MemberVariable in
                return ((comment ? varToken.0 : nil),
                        typeConvertor(varToken.1),
                        varToken.2,
                        (varToken.3.map(TypeToIRType), varToken.4, nil),
                        varToken.5,
                        varToken.6)}
            .map{(memberVariable: MemberVariable) -> (MemberVariable) in
                return rewrittenRefInPrototype(src: src, memberVariable: memberVariable)}
    }
    
    static func deduceReferenceMap(typeConvertor: @escaping (Type) -> IRType,
                                   tokenList: [MemberVariableToken]) -> [Variable : String] {
        return tokenList
            .map{(varToken: MemberVariableToken) -> MemberVariable in
                return (nil,
                        typeConvertor(varToken.1),
                        varToken.2,
                        (varToken.3.map(TypeToIRType), varToken.4, nil),
                        varToken.5,
                        varToken.6)
            }
            .flatMap{(memberVariable: MemberVariable) -> (Variable, String)? in
                if let path = findRefPathInPrototype(memberVariable: memberVariable) {
                    return (finalVariable(memberVariable: memberVariable), path)
                } else {
                    return nil
                }
            }
            .reduce([:], {
                var dic = $0
                dic[$1.0] = $1.1
                return dic
            })
    }
    
    static func deduceOptions(options: AnalysisOptions) -> GenerateModules {
        var res = GenerateModules()
        
        res.append(.prototypeInitializer)
        if options[.initializerPreprocess] != nil {
            res.append(.prototypeInitializerPreprocess)
        }
        if options[.immutable] != nil {
            res.append(.mutableVersion)
            res.append(.unidirectionalDataflow)
        } else if options[.unidirectionDataflow] != nil {
            res.append(.unidirectionalDataflow)
        }
        
        res.append(.archive)
        res.append(.copy)
        res.append(.equality)
        res.append(.print)
        res.append(.hash)
        
        return res
    }
    
    fileprivate static func rewrittenRefInPrototype(src: String, memberVariable: MemberVariable) -> MemberVariable {
        if let ir = parseIRIfNeededInPrototype(src: src, memberVariable: memberVariable) {
            let originalType = memberVariable.1.setNestedType(desType: ir.srcName)
            return (memberVariable.0,
                    originalType,
                    memberVariable.2,
                    (rewrittenType(originalType: originalType, designedType: IRType.ambiguous(type: ir.desName)), memberVariable.3?.1, RewrittenFormat.formatFrom(describeFormat: ir.inputFormat)),
                    memberVariable.4,
                    memberVariable.5)
            
        } else {
            return (memberVariable.0,
                    memberVariable.1,
                    memberVariable.2,
                    (memberVariable.3?.0.flatMap{rewrittenType(originalType: memberVariable.1, designedType: $0)}, memberVariable.3?.1, nil),
                    memberVariable.4,
                    memberVariable.5)
        }
    }
    
    fileprivate static func findRefPathInPrototype(memberVariable: MemberVariable) -> String? {
        var path: String?
        
        if let designedType = memberVariable.3?.0 {
            path = parseIRPathIfNeededInPrototype(originalType: memberVariable.1, designedType: designedType)
        }
        
        return path
    }
    
    fileprivate static func parseIRIfNeededInPrototype(src: String, memberVariable: MemberVariable) -> IR? {
        if let designedType = memberVariable.3?.0 {
            return parseRef(src: src, reference: parseIRPathIfNeededInPrototype(originalType: memberVariable.1, designedType: designedType))
        } else {
            return nil
        }
    }
    
    fileprivate static func parseIRPathIfNeededInPrototype(originalType: IRType, designedType: IRType) -> String? {
        switch (originalType, designedType) {
        case (.string, .ambiguous(let type)),
             (.ambiguous(_), .ambiguous(let type)),
             (.array(_), .ambiguous(let type)),
             (.map(_), .ambiguous(let type)),
             (.any, .ambiguous(let type)):
            return parseRefPath(reference: type)
        default:
            return nil
        }
    }
}

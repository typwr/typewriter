//
//  SwiftCodableGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/22.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension SwiftModelElementGenerator {
    func generateCodableComponent(ir: IR) -> Swift.ProtocolComponent {
        guard ir.isContainFlattenMemberVariable() || ir.isContainBuildInRewrittenType() else {
            return ("Codable", nil, nil)
        }
        
        return ("Codable", nil, [generateDecodeFunc(ir: ir), generateEncodeFunc(ir: ir)])
    }

    func generateEncodeFunc(ir: IR) -> Swift.Funcz {
        return Swift.Func(accessControl: .publicz,
                          decoration: [],
                          generic: nil,
                          constraint: nil,
                          decl: "encode",
                          parameter: "to encoder: Encoder",
                          throwing: true,
                          returnType: nil,
                          body: {
                            return generateEncodeStmt(ir: ir)
        })
    }
    
    func generateDecodeFunc(ir: IR) -> Swift.Funcz {
        return Swift.CompoundDecl.initializerDecl(accessControl: .publicz,
                                                  decoration: ir.isMemberVariableReadOnly() ? [] : [.required],
                                                  optional: .required,
                                                  parameter: "from decoder: Decoder",
                                                  throwing: true,
                                                  stmt: {
                                                    return generateDecodeStmt(ir: ir)
        })
    }
    
    fileprivate func generateEncodeStmt(ir: IR) -> [String] {
        var res = [String]()
        var noneLeafNode = [String: String]()
        let hierarchy = ir.memberVariableHierarchy()
        let memberVariableMap = ir.makeMemberVariableMap()
        
        hierarchy.forEach { (element) in
            noneLeafNode[element.1] = element.1
        }
        
        hierarchy.forEach { (element) in
            if element.1 == ir.memberVariableRootPlaceHolder() {
                res.append("var container = encoder.container(keyedBy: \(codingKeysEnumName()).self)")
            }
            
            element.2.forEach({ (child) in
                if noneLeafNode[child] != nil && element.1 == ir.memberVariableRootPlaceHolder() {
                    res.append("var \(child)Container = container.nestedContainer(keyedBy: \(child)CodingKeys.self, forKey: .\(child))")
                } else if noneLeafNode[child] != nil && element.1 != ir.memberVariableRootPlaceHolder() {
                    res.append("var \(child)Container = \(element.1)Container.nestedContainer(keyedBy: \(child)CodingKeys.self, forKey: .\(child))")
                } else if element.1 == ir.memberVariableRootPlaceHolder() {
                    let memberVariable = memberVariableMap[child]!
                    
                    //区分同时 基础类型重写 和 optional
                    if let rewrittenType = generateBuildInRewrittenType(memberVariable: memberVariable) {
                        switch Swift.Optional.from(nullable: memberVariable.4) {
                        case .optional:
                            let stmt = Swift.CompoundStmt.ifStmt(condition: "let \(child) = \(child)", stmt: {
                                ["try container.encode(\(rewrittenType)(\(child)), forKey: .\(child))"]
                            })
                            res.append(stmt)
                        default:
                            res.append("try container.encode(\(rewrittenType)(\(child)), forKey: .\(child))")
                        }
                    } else {
                        res.append("try container.encode(\(child), forKey: .\(child))")
                    }
                } else {
                    let memberVariable = memberVariableMap[child]!
                    
                    //区分同时 基础类型重写 和 optional
                    if let rewrittenType = generateBuildInRewrittenType(memberVariable: memberVariable) {
                        switch Swift.Optional.from(nullable: memberVariable.4) {
                        case .optional:
                            let stmt = Swift.CompoundStmt.ifStmt(condition: "let \(child) = \(child)", stmt: {
                                ["try \(element.1)Container.encode(\(rewrittenType)(\(child)), forKey: .\(child))"]
                            })
                            res.append(stmt)
                        default:
                            res.append("try \(element.1)Container.encode(\(rewrittenType)(\(child)), forKey: .\(child))")
                        }
                    } else {
                        res.append("try \(element.1)Container.encode(\(child), forKey: .\(child))")
                    }
                }
            })
        }
        
        return res
    }
    
    fileprivate func generateDecodeStmt(ir: IR) -> [String] {
        var res = [String]()
        var noneLeafNode = [String: String]()
        var rewrittenTypeWithOptionalMap = [Variable: Type]()
        var originalTypeWithOptionalMap = [Variable: Type]()
        let hierarchy = ir.memberVariableHierarchy()
        let memberVariableMap = ir.makeMemberVariableMap()
        
        hierarchy.forEach { (element) in
            noneLeafNode[element.1] = element.1
        }
        
        ir.memberVariableList.forEach { (element) in
            let convertor = irTypeConvertor(forLanguage: .Swift)
            let type = finalType(memberVariable: element)
            let variable = finalVariable(memberVariable: element)
            
            switch Swift.Optional.from(nullable: element.4) {
            case .optional:
                rewrittenTypeWithOptionalMap[variable] = "\(convertor(type))\(Swift.Optional.from(nullable: element.4).rawValue)"
                originalTypeWithOptionalMap[variable] = "\(convertor(element.1))\(Swift.Optional.from(nullable: element.4).rawValue)"
            default:
                rewrittenTypeWithOptionalMap[variable] = convertor(type)
                originalTypeWithOptionalMap[variable] = convertor(element.1)
            }
        }
        
        hierarchy.forEach { (element) in
            if element.1 == ir.memberVariableRootPlaceHolder() {
                res.append("let container = try decoder.container(keyedBy: \(codingKeysEnumName()).self)")
            }
            
            element.2.forEach({ (child) in
                if noneLeafNode[child] != nil && element.1 == ir.memberVariableRootPlaceHolder() {
                    res.append("let \(child)Container = try container.nestedContainer(keyedBy: \(child)CodingKeys.self, forKey: .\(child))")
                } else if noneLeafNode[child] != nil && element.1 != ir.memberVariableRootPlaceHolder() {
                    res.append("let \(child)Container = try \(element.1)Container.nestedContainer(keyedBy: \(child)CodingKeys.self, forKey: .\(child))")
                } else if element.1 == ir.memberVariableRootPlaceHolder() {
                    let memberVariable = memberVariableMap[child]!
                    
                    /*
                     区分基础类型的重写 和 如果是基础类型重写是否是optional
                    */
                    if let rewrittenType =  generateBuildInRewrittenType(memberVariable: memberVariable),
                        let defaultValue = generateBuildInRewrittenDefaultValue(memberVariable: memberVariable) {
                        
                        switch Swift.Optional.from(nullable: memberVariable.4) {
                        case .optional:
                            let stmt = Swift.CompoundStmt.ifStmt(condition: "let \(child) = try container.decode(\(originalTypeWithOptionalMap[child]!).self, forKey: .\(child))", stmt: {
                                ["self.\(child) = \(rewrittenType)(\(child))"]
                            })
                            res.append(stmt)
                        default:
                            res.append("self.\(child) = try \(rewrittenType)(container.decode(\(originalTypeWithOptionalMap[child]!).self, forKey: .\(child))) ?? \(defaultValue)")
                        }
                    } else {
                        res.append("self.\(child) = try container.decode(\(rewrittenTypeWithOptionalMap[child]!).self, forKey: .\(child))")
                    }
                } else {
                    let memberVariable = memberVariableMap[child]!

                    /*
                     区分基础类型的重写 和 如果是基础类型重写是否是optional
                     */
                    if let rewrittenType =  generateBuildInRewrittenType(memberVariable: memberVariable),
                        let defaultValue = generateBuildInRewrittenDefaultValue(memberVariable: memberVariable) {
                        switch Swift.Optional.from(nullable: memberVariable.4) {
                        case .optional:
                            let stmt = Swift.CompoundStmt.ifStmt(condition: "let \(child) = try \(element.1)Container.decode(\(originalTypeWithOptionalMap[child]!).self, forKey: .\(child))", stmt: {
                                ["self.\(child) = \(rewrittenType)(\(child))"]
                            })
                            res.append(stmt)

                        default:
                            res.append("self.\(child) = try \(rewrittenType)(\(element.1)Container.decode(\(originalTypeWithOptionalMap[child]!).self, forKey: .\(child))) ?? \(defaultValue)")
                        }
                    } else {
                        res.append("self.\(child) = try \(element.1)Container.decode(\(rewrittenTypeWithOptionalMap[child]!).self, forKey: .\(child))")
                    }
                }
            })
        }
        
        return res
    }
    
    fileprivate func generateBuildInRewrittenType(memberVariable: MemberVariable) -> Type? {
        let convertor = irTypeConvertor(forLanguage: .Swift)
        
        return memberVariable.3?.0.flatMap({ rewrittenType -> String? in
            switch (memberVariable.1, rewrittenType) {
            case (.string, .float):
                return convertor(rewrittenType)
            case (.string, .double):
                return convertor(rewrittenType)
            case (.string, .sint32):
                return convertor(rewrittenType)
            case (.string, .sint64):
                return convertor(rewrittenType)
            case (.string, .uint32):
                return convertor(rewrittenType)
            case (.string, .uint64):
                return convertor(rewrittenType)
            case (.string, .bool):
                return convertor(rewrittenType)
            default:
                return nil
            }
        })
    }
    
    fileprivate func generateBuildInRewrittenDefaultValue(memberVariable: MemberVariable) -> String? {
        return memberVariable.3?.0.flatMap({ rewrittenType -> String? in
            switch (memberVariable.1, rewrittenType) {
            case (.string, .float):
                return "0.0"
            case (.string, .double):
                return "0.0"
            case (.string, .sint32):
                return "0"
            case (.string, .sint64):
                return "0"
            case (.string, .uint32):
                return "0"
            case (.string, .uint64):
                return "0"
            case (.string, .bool):
                return "false"
            default:
                return nil
            }
        })
    }

}

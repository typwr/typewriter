//
//  SwiftModelElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/7.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension IRType {
    func isContainAny() -> Bool {
        switch self {
        case .float, .double, .uint32, .uint64, .sint32, .sint64, .bool, .string, .date, .ambiguous:
            return false
        case .any:
            return true
        case .array(let type):
            return type?.isContainAny() ?? false
        case .map(_, let valueType):
            return valueType?.isContainAny() ?? false
        }
    }
}

struct SwiftModelElementGenerator {
    let ir: IR
    
    func generateSwifMemberVariableType(memberVariable: MemberVariable) -> Type {
        let convertor = irTypeConvertor(forLanguage: .Swift)
        let type = finalType(memberVariable: memberVariable)
        return "\(convertor(type))\(Swift.Optional.from(nullable: memberVariable.4))"
    }
    
    func generateSwiftMemberVariable(ir: IR, immutability: Swift.Immutability) -> [Swift.MemberVariable] {
        let convertor = irTypeConvertor(forLanguage: .Swift)
        return ir.memberVariableList.map{ (memberVariable: MemberVariable) -> Swift.MemberVariable in
            let type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)
            
            if variable == ir.modelId() {
                return (memberVariable.0,
                        Swift.AccessControl.publicz,
                        [],
                        Swift.Immutability.varz,
                        Swift.Optional.from(nullable: memberVariable.4),
                        convertor(type),
                        variable)
            } else {
                return (memberVariable.0,
                        Swift.AccessControl.publicz,
                        [],
                        immutability,
                        Swift.Optional.from(nullable: memberVariable.4),
                        convertor(type),
                        variable)
            }
        }
    }
    
    func generateElements() -> [Swift.Element] {
        guard ir.inputFormat == .JSON else {
            return []
        }
        
        var elements: [Swift.Element] = [Swift.Element.importz(files: ["Foundation"])]
        var funcs: [Swift.Funcz] = []
        let srcImplement = ir.srcImplement.map { implements -> [Swift.ProtocolComponent] in
            return implements.map({ implement -> Swift.ProtocolComponent in
                return (implement, nil, nil)
            })
        } ?? []
        
        if ir.isMemberVariableReadOnly() {
            for module in ir.generateModules {
                switch module {
                case .jsonInitializer:
                    funcs.append(generateJsonInitailizer(ir: ir))
                case .mutableVersion:
                    funcs.append(generateLetModelInitializerFunc(ir: ir))
                    funcs.append(generateMergeFunc(ir: ir))
                default:
                    break
                }
            }
            
            
            
            elements.append(Swift.Element.structz(name: ir.desName,
                                                  accessControl: .publicz,
                                                  generic: nil,
                                                  component: deduceCodingKeysEnum(ir: ir),
                                                  protocolComponent: srcImplement + [generateCodableComponent(ir: ir)],
                                                  typeDecl: nil,
                                                  memberVariable: generateSwiftMemberVariable(ir: ir, immutability: Swift.Immutability.letz),
                                                  funcz: funcs))
            
            if ir.containModule(type: .mutableVersion) {
                elements.append(generateStructVariable(ir: ir))
            }
        } else {
            for module in ir.generateModules {
                switch module {
                case .jsonInitializer:
                    funcs.append(generateJsonInitailizer(ir: ir))
                default:
                    break
                }
            }
            
            if !ir.isContainFlattenMemberVariable() {
                funcs.append(generateInitializerFunc(ir: ir))
            }
            
            elements.append(Swift.Element.classz(name: ir.desName,
                                                 inherited: ir.desInheriting,
                                                 accessControl: .publicz,
                                                 decoration: [Swift.ClassDecoration.none],
                                                 generic: nil,
                                                 component: deduceCodingKeysEnum(ir: ir),
                                                 protocolComponent: srcImplement + [generateCodableComponent(ir: ir)],
                                                 typeDecl: nil,
                                                 memberVariable: generateSwiftMemberVariable(ir: ir, immutability: Swift.Immutability.varz),
                                                 funcz: funcs))
        }
        
        if ir.isModelUnique() {
            elements.append(generateUnidirectionalDataflowExtension(ir: ir))
        }
        
        return elements
            .filter{(element : Swift.Element) -> Bool in
                switch element {
                case .none:
                    return false
                default:
                    return true
                }
        }
    }    
}

extension SwiftModelElementGenerator {
    func generateInitializerFunc(ir: IR) -> Swift.Funcz {
        let convertor = irTypeConvertor(forLanguage: .Swift)
        let parameter = ir.memberVariableList.map { (memberVariable) -> String in
            let type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)
            return "\(variable): \(convertor(type))"
        }.joined(separator: ", ")
        
        return Swift.CompoundDecl.initializerDecl(accessControl: .publicz,
                                                  decoration: [],
                                                  optional: .required,
                                                  parameter: parameter,
                                                  throwing: false,
                                                  stmt: {
            return ir.memberVariableList.map{ (memberVariable) -> String in
                let variable = finalVariable(memberVariable: memberVariable)
                return "self.\(variable) = \(variable)"
            }
        })
    }
}


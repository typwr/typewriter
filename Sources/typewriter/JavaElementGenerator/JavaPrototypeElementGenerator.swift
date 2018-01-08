//
//  JavaPrototypeElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/14.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension JavaModelElementGenerator {
    func generatePrototypeInitializer(ir: IR) -> Java.Methodz {
        let isModelUnique = ir.isModelUnique()
        
        let preprocessCall = ir.containModule(type: .prototypeInitializerPreprocess) ?generatePrototypeInitializerPreprocessCall(ir: ir) : []
        
        let dataflowCall = isModelUnique ? generateUndirectionalDataflowCall(ir: ir, entity: "this", identify: "this") : []
        
        let name = ir.containModule(type: .prototypeInitializerPreprocess) ? "preprocess" : "prototype";
        
        let originalAssignStmt = ir.memberVariableList.flatMap{generateOriginalAssignStmt(memberVariable: $0, name: name)}
        
        let modelIdStmt = isModelUnique ? ["this.\(ir.modelId()) = \(ir.modelId());"] : []
        
        let rewrittenAssignStmt = ir.memberVariableList.flatMap{generateRewrittenAssignStmt(memberVariable: $0, name: name)}
        
        let jsonMixInPrototypeStmt = ir.memberVariableList.flatMap{generateJSONMixInPrototypeStmt(ir: ir, memberVariable: $0, name: name)}
        
        let complexStmt = preprocessCall + modelIdStmt + originalAssignStmt + rewrittenAssignStmt + jsonMixInPrototypeStmt + dataflowCall
        
        return Java.Method(annotations: ["@SuppressWarnings(\("unchecked".javaLiteral()))"],
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: ir.desName,
                           parameter: isModelUnique ? "\(ir.srcName) prototype, String \(ir.modelId())" : "\(ir.srcName) prototype" ,
                           throwsz: nil,
                           returnType: nil,
                           body: {
                            complexStmt
        })
    }
    
    private func generateOriginalAssignStmt(memberVariable: MemberVariable, name: String) -> String? {
        let rewrittenType = memberVariable.3?.0
        if rewrittenType != nil {
            return nil
        }
        let variable = finalVariable(memberVariable: memberVariable)
        if variable == ir.modelId() {
            return nil
        }
        return "this.\(variable) = \(name).\(memberVariable.2);"
    }
    
    private func generateRewrittenAssignStmt(memberVariable: MemberVariable, name: String) -> String? {
        guard let rewrittenType = memberVariable.3?.0 else {
            return nil
        }
        
        let originalType = memberVariable.1
        let variable = finalVariable(memberVariable: memberVariable)
        let typeConvertor = irTypeConvertor(forLanguage: .Java)
        
        switch (originalType, rewrittenType) {
        case (.string, .ambiguous(let type)):
            if memberVariable.3?.2 == nil {
                return "this.\(variable) = \(type).\(enumFromJSONMethodName())(\(name).\(memberVariable.2));"
            } else {
                return nil
            }
        case (.string, .float):
            return "this.\(variable) = Float.parseFloat(\(name).\(memberVariable.2));"
        case (.string, .double):
            return "this.\(variable) = Double.parseDouble(\(name).\(memberVariable.2));"
        case (.string, .sint32):
            return "this.\(variable) = Integer.parseInt(\(name).\(memberVariable.2));"
        case (.string, .sint64):
            return "this.\(variable) = Long.parseLong(\(name).\(memberVariable.2));"
        case (.string, .uint32):
            return "this.\(variable) = Integer.parseInt(\(name).\(memberVariable.2));"
        case (.string, .uint64):
            return "this.\(variable) = Long.parseLong(\(name).\(memberVariable.2));"
        case (.string, .bool):
            return "this.\(variable) = Boolean.parseBoolean(\(name).\(memberVariable.2));"
        case (.ambiguous, .ambiguous):
            if let rewrittenFormat = memberVariable.3?.2 {
                switch rewrittenFormat {
                case .prototype:
                    return "this.\(variable) = (\(typeConvertor(rewrittenType)))transformModelFromPrototype(\(name).\(memberVariable.2));"
                default:
                    return nil
                }
            }
        case (.array, .array), (.map, .map):
            if let rewrittenFormat = memberVariable.3?.2 {
                switch rewrittenFormat {
                case .prototype:
                    return "this.\(variable) = (\(typeConvertor(rewrittenType)))transformModelFromPrototype(\(name).\(memberVariable.2));"
                default:
                    return nil
                }
            }
        default:
            return nil
        }
        
        return nil
    }
    
    private func generateJSONMixInPrototypeStmt(ir: IR, memberVariable: MemberVariable, name: Variable) -> String? {
        var stmt: String?
        let typeConvertor = irTypeConvertor(forLanguage: .Java)
        
        if let rewrittenFormat = memberVariable.3?.2, let rewrittenType = memberVariable.3?.0 {
            switch rewrittenFormat {
            case .json:
                let variable = finalVariable(memberVariable: memberVariable)
                if let referenceIR = ir.jumpToReferenceIR(variable: variable) {
                    if referenceIR.isModelUnique() {
                        if ir.isModelUnique() {
                            stmt = "this.\(variable) = \(typeConvertor(rewrittenType)).modelWithJSON(\(name).\(memberVariable.2), \(ir.modelId()));"
                        } else {
                            stmt = "this.\(variable) = \(typeConvertor(rewrittenType)).modelWithJSON(\(name).\(memberVariable.2));"
                        }
                    }
                }
            default:
                break
            }
        }

        return stmt
    }
}

//
//  SwiftStructVariableElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/7.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension SwiftModelElementGenerator {
    private func structVariableName(ir: IR) -> String {
        return "\(ir.desName)Variable"
    }
    
    func generateLetModelInitializerFunc(ir: IR) -> Swift.Funcz {
        return Swift.CompoundDecl.initializerDecl(accessControl: .publicz,
                                                  decoration: [],
                                                  optional: .required,
                                                  parameter: "varModel: \(structVariableName(ir: ir))",
                                                  throwing: false,
                                                  stmt: {
            ir.memberVariableList.map{ (memberVariable) -> String in
                let variable = finalVariable(memberVariable: memberVariable)
                return "\(variable) = varModel.\(variable)"
            } +
            generateUndirectionalDataflowCall(ir: ir, modelName: "self", modelIdName: "varModel")
        })
    }
    
    func generateMergeFunc(ir: IR) -> Swift.Funcz {
        return Swift.Func(accessControl: .publicz,
                          decoration: [],
                          generic: nil,
                          constraint: nil,
                          decl: "merge",
                          parameter: "varModel: ((inout \(structVariableName(ir: ir))) -> ())",
                          throwing: false,
                          returnType: nil,
                          body: {
            ["var mutableModel = \(structVariableName(ir: ir))(letModel: self)",
             "varModel(&mutableModel)",
             "_ = mutableModel.letModel()"]
        })
    }
    
    private func generateVariableModelInitializerFunc(ir: IR) -> Swift.Funcz {
        return Swift.CompoundDecl.initializerDecl(accessControl: .publicz,
                                                  decoration: [],
                                                  optional: .required,
                                                  parameter: "letModel: \(ir.desName)",
                                                  throwing: false,
                                                  stmt: {
            ir.memberVariableList.map{ (memberVariable) -> String in
                let variable = memberVariable.3?.1 ?? memberVariable.2
                return "\(variable) = letModel.\(variable)"
            }
        })
    }
    
    private func generateLetFunc(ir: IR) -> Swift.Funcz {
        return Swift.Func(accessControl: .publicz,
                          decoration: [],
                          generic: nil,
                          constraint: nil,
                          decl: "letModel",
                          parameter: nil,
                          throwing: false,
                          returnType: ir.desName,
                          body: {
            ["return \(ir.desName)(varModel: self)"]
        })
    }
    
    func generateStructVariable(ir: IR) -> Swift.Element {
        return Swift.Element.structz(name: structVariableName(ir: ir),
                                     accessControl: .publicz,
                                     generic: nil,
                                     component: nil,
                                     protocolComponent: nil,
                                     typeDecl: nil,
                                     memberVariable: generateSwiftMemberVariable(ir: ir, immutability: Swift.Immutability.varz),
                                     funcz: [generateVariableModelInitializerFunc(ir: ir),
                                             generateLetFunc(ir: ir)])
    }
}

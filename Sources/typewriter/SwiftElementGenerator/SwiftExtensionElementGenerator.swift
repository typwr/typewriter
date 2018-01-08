//
//  SwiftExtensionElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/7.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension SwiftModelElementGenerator {
    func generateUndirectionalDataflowCall(ir: IR, modelName: String, modelIdName: String) -> [String] {
        return ["\(ir.desName).unidirectionalDataflow(model: \(modelName), \(ir.modelId()): \(modelIdName).\(ir.modelId()))"]
    }
        
    func generateUnidirectionalDataflowFunc(ir: IR) -> Swift.Funcz {
        return Swift.Func(accessControl: .publicz,
                          decoration: ir.isMemberVariableReadOnly() ? [Swift.FuncDecoration.staticz] : [Swift.FuncDecoration.classz],
                          generic: nil,
                          constraint: nil,
                          decl: "unidirectionalDataflow",
                          parameter: "model: \(ir.desName), \(ir.modelId()): String?",
                          throwing: false,
                          returnType: nil,
                          body: {
            ["// unidirectional data flow"]
        })
    }
    
    func generateUnidirectionalDataflowExtension(ir: IR) -> Swift.Element {
        return Swift.Element.extensionz(name: ir.desName,
                                        accessControl: .publicz,
                                        constraint: nil,
                                        component: nil,
                                        protocolComponent: nil,
                                        typeDecl: nil,
                                        memberVariable: nil,
                                        funcz: [generateUnidirectionalDataflowFunc(ir: ir)])
    }
}

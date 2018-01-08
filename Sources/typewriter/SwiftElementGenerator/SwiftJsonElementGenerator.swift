//
//  SwiftJsonElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/23.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension SwiftModelElementGenerator {
    func generateJsonInitailizer(ir: IR) -> Swift.Funcz {
        let isModelUnique = ir.isModelUnique()
        let dataflowCall = isModelUnique ? generateUndirectionalDataflowCall(ir: ir, modelName: "model", modelIdName: "model") : []
        let modelIdStmt = isModelUnique ?
            ([Swift.CompoundStmt.ifStmt(condition: "let \(ir.modelId()) = \(ir.modelId())", stmt: {
                ["model.\(ir.modelId()) = \(ir.modelId())"]
            })]) : []
        let mutableDecl = ir.isMemberVariableReadOnly() ? (isModelUnique ? "var" : "let") : "let"
        
        return Swift.Func(accessControl: .none,
                          decoration: ir.isMemberVariableReadOnly() ?
                            [Swift.FuncDecoration.staticz] : [Swift.FuncDecoration.classz],
                          generic: nil,
                          constraint: nil,
                          decl: "modelWithJson",
                          parameter: isModelUnique ? "json: Data, \(ir.modelId()): String?" : "json: Data",
                          throwing: true,
                          returnType: ir.desName,
                          body: {
                            return ["\(mutableDecl) model = try JSONDecoder().decode(\(ir.desName).self, from: json)"] +
                                    modelIdStmt +
                                    dataflowCall +
                                    ["return model"]
        })
    }
}



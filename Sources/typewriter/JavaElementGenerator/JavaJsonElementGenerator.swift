//
//  JavaJsonElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/14.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension JavaModelElementGenerator {
    func generateJsonInitailizer(ir: IR) -> Java.Methodz {
        let isModelUnique = ir.isModelUnique()
        let dataflowCall = isModelUnique ? generateUndirectionalDataflowCall(ir: ir, entity: "model", identify: nil) : []
        let modelIdStmt = isModelUnique ?
            ([Java.CompoundStmt.ifStmt(condition: "model != null && \(ir.modelId()) != null", stmt: {
                ["model.\(ir.modelId()) = \(ir.modelId());"]
            })]) : []
        
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.staticz],
                           generic: nil,
                           decl: "modelWithJSON",
                           parameter: isModelUnique ? "String json, String \(ir.modelId())" : "String json",
                           throwsz: nil,
                           returnType: ir.desName,
                           body: {
                            if isModelUnique {
                                return ["\(ir.desName) model = \(ir.desName).fieldsMapWithJSON(json, \(ir.desName).class);"] +
                                    modelIdStmt +
                                    dataflowCall +
                                    ["return model;"]
                            } else {
                                return ["return \(ir.desName).fieldsMapWithJSON(json, \(ir.desName).class);"]
                            }
        })
    }
}

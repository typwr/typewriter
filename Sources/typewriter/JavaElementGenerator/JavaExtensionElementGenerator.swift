//
//  JavaExtensionElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/14.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension JavaModelElementGenerator {
    func generatePrototypeInitializerPreprocessMethod(ir: IR) -> Java.Methodz {
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: "initializerPreprocess",
                           parameter: "\(ir.srcName) preprocess",
                           throwsz: nil,
                           returnType: ir.srcName,
                           body: {
                            return ["return preprocess;"]
        })
    }
    
    func generateUnidirectionalDataflowMethod(ir: IR) -> Java.Methodz {
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.staticz],
                           generic: nil,
                           decl: "unidirectionalDataflow",
                           parameter: "\(ir.desName) model, String \(ir.modelId())",
                           throwsz: nil,
                           returnType: "void",
                           body: {
                            ["// unidirectional data flow"]
        })
    }
    
    func generatePrototypeInitializerPreprocessCall(ir: IR) -> [String] {
        return ["\(ir.srcName) preprocess = initializerPreprocess(prototype);"]
    }
    
    func generateUndirectionalDataflowCall(ir: IR, entity: String, identify: String?) -> [String] {
        return ["\(ir.desName).unidirectionalDataflow(\(entity), \(identify != nil ? "\(identify!)." : "")\(ir.modelId()));"]
    }
}

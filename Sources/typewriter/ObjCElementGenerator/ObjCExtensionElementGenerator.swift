//
//  ObjCExtensionElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/26.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension ObjCModelElementGenerator {
    func generatePrototypeInitializerPreprocessMethod(ir: IR) -> ObjC.Methodz {
        return ObjC.Method(decl: "- (\(ir.srcName) *)initializerPreprocess:(\(ir.srcName) *)preprocess", impl: {
            ["return preprocess;"]
        })
    }
    
    func generateJSONInitializerPreprocessMethod() -> ObjC.Methodz {
        return ObjC.Method(decl: "- (id)initializerPreprocess:(id)preprocess", impl: {
            return ["return preprocess;"]
        })
    }
    
    func generateUnidirectionalDataflowMethod(ir: IR) -> ObjC.Methodz {
        return ObjC.Method(decl: "+ (void)unidirectionalDataflow:(\(ir.desName) *)model \(ir.modelId()):(NSString *)\(ir.modelId())", impl: {
            ["// unidirectional data flow"]
        })
    }
    
    func generateUndirectionalDataflowCall(ir: IR) -> [String] {
        return ["[\(ir.desName) unidirectionalDataflow:self \(ir.modelId()):self.\(ir.modelId())];"]
    }
    
    func generatePrototypeInitializerPreprocessCall(ir: IR) -> [String] {
        return ["\(ir.srcName) *preprocess = [self initializerPreprocess:prototype];"]
    }
    
    func generateJSONInitializerPreprocessCall() -> [String] {
        return ["id preprocess = [self initializerPreprocess:json];"]
    }
}

//
//  ObjCJSONMapElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/22.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension ObjCModelElementGenerator {
    func generateModelFromJSONInitalizer(ir: IR) -> ObjC.Methodz {
        let isModelUnique = ir.isModelUnique()
        
        let decl = isModelUnique ?
            "- (nullable instancetype)initWithJSON:(id)json \(ir.modelId()):(NSString *)\(ir.modelId())" :
            "- (nullable instancetype)initWithJSON:(id)json"
        
        let preprocessCall = ir.containModule(type: .jsonInitializerPreprocess) ? generateJSONInitializerPreprocessCall() : []
        
        let dataflowCall = isModelUnique ? generateUndirectionalDataflowCall(ir: ir) : []
        
        let name = ir.containModule(type: .jsonInitializerPreprocess) ? "preprocess" : "json"
        
        let modelIdStmt = isModelUnique ? ["self->_\(ir.modelId()) = \(ir.modelId());"] : []
        
        let complexStmt = modelIdStmt +
            dataflowCall +
            ["return self;"]
        
        return ObjC.Method(decl: decl, impl: {
            return ["NSParameterAssert(json);",
                    ObjC.CompoundStmt.ifStmt(condition: "!(self = [super init])", stmt: {
                        return ["return nil;"]
                    })] +
                    preprocessCall +
                    [ObjC.CompoundStmt.ifStmt(condition: "![self propertyMapWithJSON:\(name)]", stmt: {
                        return ["return nil;"]
                    })] +
                    complexStmt
        })
    }
    
    func generateModelClassFromJSONInitalizer(ir: IR) -> ObjC.Methodz {
        let isModelUnique = ir.isModelUnique()
        
        let decl = isModelUnique ?
            "+ (nullable instancetype)modelWithJSON:(id)json \(ir.modelId()):(NSString *)\(ir.modelId())" :
            "+ (nullable instancetype)modelWithJSON:(id)json"
        
        let stmt = isModelUnique ?
            "return [[self alloc] initWithJSON:json \(ir.modelId()):\(ir.modelId())];" :
            "return [[self alloc] initWithJSON:json];"
        
        return ObjC.Method(decl: decl, impl: {
            return [stmt]
        })
    }
}

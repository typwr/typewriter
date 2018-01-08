//
//  ObjCBuilderElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/18.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension ObjCModelElementGenerator {
    func generateBuilderClass(ir: IR) -> ObjC.Element {
        return ObjC.Element.classz(name: builderClassName(),
                                   inherited: ir.desInheriting,
                                   protocols: nil,
                                   properties: generateBuilderProperty(ir: ir),
                                   methods: [(ObjC.MethodVisibility.publicMethod, generateBuilderInitializerMethod(ir: ir)),
                                             (ObjC.MethodVisibility.publicMethod, generateBuildMethod(ir: ir))])
        
    }
    
    func generateModelBuilderInitializerMethod(ir: IR) -> ObjC.Methodz {
        return ObjC.Method(decl: "- (instancetype)initWith\(builderClassName()):(\(builderClassName()) *)builder",
            impl: {
            ["NSParameterAssert(builder);",
             ObjC.CompoundStmt.ifStmt(condition: "!(self = [super init])", stmt: {
                ["return self;"]
             }),
             "[self propertyMapWithPrototype:builder mapping:@{\(ir.memberVariableList.map{generatePropertyNameDicStmt(memberVariable: $0)}.joined(separator: ",\n\("[self propertyMapWithPrototype:builder mapping:@{".whitespaces())"))}];",
                (ir.isModelUnique() ?
                    generateUndirectionalDataflowCall(ir:ir).joined() : ""),
                "return self;"]
                .filter{!$0.isEmpty}
        })
    }
    
    func generateMergeBlockMethod(ir: IR) -> ObjC.Methodz {
        return ObjC.Method(decl: "- (instancetype)mergeWithBlock:(void(^)(\(builderClassName()) *builder))block", impl: {
            ["NSParameterAssert(block);",
             "\(builderClassName()) *builder = [[\(builderClassName()) alloc] initWith\(ir.desName):self];",
                "block(builder);",
                "return [builder build];"]
        })
    }
    
    func generateBuilderInitializerMethod(ir: IR) -> ObjC.Methodz {
        return ObjC.Method(decl: "- (instancetype)initWith\(ir.desName):(\(ir.desName) *)model", impl: {
            ["NSParameterAssert(model);",
             ObjC.CompoundStmt.ifStmt(condition: "!(self = [super init])", stmt: {
                ["return self;"]
             }),
             "[self propertyMapWithPrototype:model mapping:@{\(ir.memberVariableList.map{generatePropertyNameDicStmt(memberVariable: $0)}.joined(separator: ",\n\("[self propertyMapWithPrototype:model mapping:@{".whitespaces())"))}];",
             "return self;"]
        })
    }
    
    func generateBuildMethod(ir: IR) -> ObjC.Methodz {
        return ObjC.Method(decl: "- (\(ir.desName) *)build", impl: {
            ["return [[\(ir.desName) alloc] initWith\(builderClassName()):self];"]
        })
    }
    
    func builderClassName() -> String {
        return ir.desName + "Builder"
    }
    
    private func generatePropertyNameDicStmt(memberVariable: MemberVariable) -> String {
        let variable = finalVariable(memberVariable: memberVariable)
        return "\(variable.objcLiteral()): \(variable.objcLiteral())"
    }
    
    private func generateBuilderProperty(ir: IR) -> [ObjC.Property] {
        return generateProperty(ir:ir, immutability: ObjC.Immutability.mutable)
    }
}

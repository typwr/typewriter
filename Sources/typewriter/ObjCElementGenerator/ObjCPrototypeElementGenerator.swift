//
//  ObjCPrototypeElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/17.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension ObjCModelElementGenerator {
    func generateModelFromPrototypeInitializer(ir: IR) -> ObjC.Methodz {
        let isModelUnique = ir.isModelUnique()
        
        let decl = isModelUnique ?
            "- (nullable instancetype)initWith\(ir.srcName):(\(ir.srcName) *)prototype \(ir.modelId()):(nullable NSString *)\(ir.modelId())" :
            "- (nullable instancetype)initWith\(ir.srcName):(\(ir.srcName) *)prototype"
        
        let preprocessCall = ir.containModule(type: .prototypeInitializerPreprocess) ?generatePrototypeInitializerPreprocessCall(ir: ir) : []
        
        let dataflowCall = isModelUnique ? generateUndirectionalDataflowCall(ir: ir) : []
        
        let name = ir.containModule(type: .prototypeInitializerPreprocess) ? "preprocess" : "prototype";
        
        let dicMappingStmt = ir.memberVariableList.flatMap(generatePropertyDicStmt)
        
        let propertyMappingStmt = dicMappingStmt.count > 0 ? ["[self propertyMapWithPrototype:prototype mapping:@{\(dicMappingStmt.joined(separator: ",\n\("[self propertyMapWithPrototype:prototype mapping:@{".whitespaces())"))}];"]  : []
        
        let modelIdStmt = isModelUnique ? ["self->_\(ir.modelId()) = \(ir.modelId());"] : []
        
        let rewrittenAssignStmt = ir.memberVariableList.flatMap{generateRewrittenAssignStmt(memberVariable: $0, name: name)}
        
        let jsonMixInPrototypeStmt = ir.memberVariableList.flatMap{generateJSONMixInPrototypeStmt(ir: ir, memberVariable: $0, name: name)}
        
        let complexStmt = preprocessCall + propertyMappingStmt + modelIdStmt + rewrittenAssignStmt + jsonMixInPrototypeStmt + dataflowCall
        
        return ObjC.Method(decl: decl, impl: {
            ["NSParameterAssert(prototype);"] +
                [ObjC.CompoundStmt.ifStmt(condition: "!(self = [super init])", stmt: {
                    ["return nil;"]
                })] +
                complexStmt +
                ["return self;"]
        })
    }
    
    func generateModelClassFromPrototypeInitializer(ir: IR) -> ObjC.Methodz {
        let isModelUnique = ir.isModelUnique()
        
        let decl = isModelUnique ?
            "+ (nullable instancetype)modelWith\(ir.srcName):(\(ir.srcName) *)prototype \(ir.modelId()):(nullable NSString *)\(ir.modelId())" :
            "+ (nullable instancetype)modelWith\(ir.srcName):(\(ir.srcName) *)prototype"
        
        let stmt = isModelUnique ?
            "return [[self alloc] initWith\(ir.srcName):prototype \(ir.modelId()):\(ir.modelId())];" :
            "return [[self alloc] initWith\(ir.srcName):prototype];"
        
        return ObjC.Method(decl: decl, impl: {
            [stmt]
        })
    }
    
    private func generatePropertyDicStmt(memberVariable: MemberVariable) -> String? {
        let rewrittenType = memberVariable.3?.0
        if rewrittenType != nil {
            return nil
        }
        let variable = finalVariable(memberVariable: memberVariable)
        if variable == ir.modelId() {
            return nil
        }
        return "\(variable.objcLiteral()) : \(memberVariable.2.objcLiteral())"
    }
    
    private func generateRewrittenAssignStmt(memberVariable: MemberVariable, name: String) -> String? {
        guard let rewrittenType = memberVariable.3?.0 else {
            return nil
        }
        
        let originalType = memberVariable.1
        let variable = finalVariable(memberVariable: memberVariable)
        
        switch (originalType, rewrittenType) {
        case (.string, .ambiguous(let type)):
            if ObjC.isReferenceType(type: type) || memberVariable.3?.2 != nil {
                return nil
            } else {
                return "self->_\(variable) = [\(name).\(memberVariable.2) intValue];"
            }
        case (.string, .float):
            return "self->_\(variable) = [\(name).\(memberVariable.2) floatValue];"
        case (.string, .double):
            return "self->_\(variable) = [\(name).\(memberVariable.2) doubleValue];"
        case (.string, .sint32):
            return "self->_\(variable) = [\(name).\(memberVariable.2) intValue];"
        case (.string, .sint64):
            return "self->_\(variable) = [\(name).\(memberVariable.2) longLongValue];"
        case (.string, .uint32):
            return "self->_\(variable) = [@([\(name).\(memberVariable.2) intValue]) unsignedIntValue];"
        case (.string, .uint64):
            return "self->_\(variable) = [@([\(name).\(memberVariable.2) longLongValue]) unsignedLongLongValue];"
        case (.string, .bool):
            return "self->_\(variable) = [\(name).\(memberVariable.2) longLongValue];"
        case (.ambiguous(let prototypeType), .ambiguous(let modelType)):
            if ObjC.isReferenceType(type: prototypeType) && ObjC.isReferenceType(type: modelType)  {
                if let rewrittenFormat = memberVariable.3?.2 {
                    switch rewrittenFormat {
                    case .prototype:
                        return "self->_\(variable) = [self transformModelFromPrototype:\(name).\(memberVariable.2)];"
                    default:
                        return nil
                    }
                }
            }
        case (.array, .array), (.map, .map):
            if let rewrittenFormat = memberVariable.3?.2 {
                switch rewrittenFormat {
                case .prototype:
                    return "self->_\(variable) = [self transformModelFromPrototype:\(name).\(memberVariable.2)];"
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
        let typeConvertor = irTypeConvertor(forLanguage: .ObjC)
        
        if let rewrittenFormat = memberVariable.3?.2, let rewrittenType = memberVariable.3?.0 {
            switch rewrittenFormat {
            case .json:
                let variable = finalVariable(memberVariable: memberVariable)
                if let referenceIR = ir.jumpToReferenceIR(variable: variable) {
                    if referenceIR.isModelUnique() {
                        if ir.isModelUnique() {
                            stmt = "self->_\(variable) = [\(typeConvertor(rewrittenType).formatClassName()) modelWithJSON:\(name).\(memberVariable.2) \(ir.modelId()):\(ir.modelId())];"
                        } else {
                            stmt = "self->_\(variable) = [\(typeConvertor(rewrittenType).formatClassName()) modelWithJSON:\(name).\(memberVariable.2)];"
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

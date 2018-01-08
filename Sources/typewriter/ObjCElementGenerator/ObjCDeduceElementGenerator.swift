//
//  ObjCDeducexElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/24.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension ObjCModelElementGenerator {
    func deduceModelInitMethod(ir: IR) -> ObjC.Methodz? {
        guard ir.isModelUnique() && ir.inputFormat == .GPPLObjC else {
            return nil
        }
        
        return ObjC.Method(decl: "- (instancetype)init UNAVAILABLE_ATTRIBUTE", impl: {
            ["NSAssert(NO, " + ("please use designed initializer instead!").objcLiteral() + ");",
             "return nil;"]
        })
    }

    func deduceTransformModelFromPrototypeMethod(ir: IR) -> ObjC.Methodz? {
        var isNeedGen = false
        var prototypeModelMap = [Type: (Type, Variable)]()
        
        ir.memberVariableList.forEach { (memberVariable) in
            _ = memberVariable.3?.2.map{
                switch $0 {
                case .prototype:
                    if let rewrittenType = memberVariable.3?.0 {
                        switch (memberVariable.1, rewrittenType) {
                        case (.ambiguous(let prototypeType), .ambiguous(let modelType)):
                            if ObjC.isReferenceType(type: prototypeType) && ObjC.isReferenceType(type: modelType) {
                                isNeedGen = true
                                prototypeModelMap[prototypeType] = (modelType, finalVariable(memberVariable: memberVariable))
                            }
                        case (.array, .array), (.map, .map):
                            if let prototypeType = memberVariable.1.getNestedType(), let modelType = rewrittenType.getNestedType() {
                                isNeedGen = true
                                prototypeModelMap[prototypeType] = (modelType, finalVariable(memberVariable: memberVariable))
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
        
        guard isNeedGen else {
            return nil
        }
        
        return ObjC.Method(decl: "- (nullable id)transformModelFromPrototype:(id)prototype", impl: {
                [ObjC.CompoundStmt.ifStmt(condition: "!prototype", stmt: {
                    ["return nil;"]
                })] +
                prototypeModelMap.map({(prototype: Type, model: (Type, Variable)) -> String in
                    return generatePropertyModelMapWithPrototypeStmt(ir: ir,
                                                                     paramName: "prototype",
                                                                     prototype: prototype,
                                                                     model: model.0,
                                                                     variable: model.1)
                }) +
                ["return [super transformModelFromPrototype:prototype];"]
        })
    }
    
    //推断出rewritten name或者flatten的
    func deduceCustomPropertyMapperMethod(ir: IR) -> ObjC.Methodz? {
        var variableMap = [Variable: Variable]()
        let flattenMap = ir.makeFlattenMap()
        
        ir.memberVariableList.forEach { (memberVariable) in
            let variable = finalVariable(memberVariable: memberVariable)
            
            if let flattenPath = flattenMap[variable] {
                variableMap[variable] = flattenPath
            } else if let rewrittenName = memberVariable.3?.1 {
                variableMap[rewrittenName] = memberVariable.2
            }
        }

        guard variableMap.count > 0 else {
            return nil
        }
        
        return ObjC.Method(decl: "+ (NSDictionary *)customPropertyMapper", impl: {
            let dicStmt = variableMap.map{"\($0.key.objcLiteral()) : \($0.value.objcLiteral())"}
            return ["return @{\(dicStmt.joined(separator: ",\n\("return @{".whitespaces())"))};"]
        })
    }
    
    func deduceArrayGenericClassMapperMethod(ir: IR) -> ObjC.Methodz? {
        guard RewrittenFormat.formatFrom(describeFormat: ir.inputFormat) == .json else {
            return nil
        }

        var isNeedGen = false
        var variableTypeMap = [Variable: Type]()
        
        ir.memberVariableList.forEach { (memberVariable) in
            _ = memberVariable.3?.0.map{
                switch (memberVariable.1, $0) {
                case (.array, .array):
                    if let modelNestedType = $0.getNestedType(), let rewrittenFormat = memberVariable.3?.2 {
                        switch rewrittenFormat {
                        case .json:
                            isNeedGen = true
                            let variable = finalVariable(memberVariable: memberVariable)
                            variableTypeMap[variable] = modelNestedType.formatClassName()
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
        }
        
        guard isNeedGen else {
            return nil
        }
        
        return ObjC.Method(decl: "+ (NSDictionary *)arrayGenericClassMapper", impl: {
            let dicStmt = variableTypeMap.map{"\($0.key.objcLiteral()) : \($0.value.objcLiteral())"}
            return ["return @{\(dicStmt.joined(separator: ",\n\("return @{".whitespaces())"))};"]
        })
    }
    
    func deduceDictionaryGenericClassMapperMethod(ir: IR) -> ObjC.Methodz? {
        guard RewrittenFormat.formatFrom(describeFormat: ir.inputFormat) == .json else {
            return nil
        }

        var isNeedGen = false
        var variableTypeMap = [Variable: Type]()
        
        ir.memberVariableList.forEach { (memberVariable) in
            _ = memberVariable.3?.0.map{
                switch (memberVariable.1, $0) {
                case (.map, .map):
                    if let modelNestedType = $0.getNestedType(), let rewrittenFormat = memberVariable.3?.2 {
                        switch rewrittenFormat {
                        case .json:
                            isNeedGen = true
                            let variable = finalVariable(memberVariable: memberVariable)
                            variableTypeMap[variable] = modelNestedType.formatClassName()
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
        }
        
        guard isNeedGen else {
            return nil
        }
        
        return ObjC.Method(decl: "+ (NSDictionary *)dictionaryGenericClassMapper", impl: {
            let dicStmt = variableTypeMap.map{"\($0.key.objcLiteral()) : \($0.value.objcLiteral())"}
            return ["return @{\(dicStmt.joined(separator: ",\n\("return @{".whitespaces())"))};"]
        })
    }
            
    private func generatePropertyModelMapWithPrototypeStmt(ir: IR,
                                                           paramName: String,
                                                           prototype: Type,
                                                           model: Type,
                                                           variable: Variable) -> String {
        var stmt = "\(model) model = [\(model.formatClassName()) modelWith\(prototype.formatClassName()):\(paramName)];"
        
        if let referenceIR = ir.jumpToReferenceIR(variable: variable) {
            if referenceIR.isModelUnique() {
                if ir.isModelUnique() {
                    stmt = "\(model) model = [\(model.formatClassName()) modelWith\(prototype.formatClassName()):\(paramName) \(ir.modelId()):self.\(ir.modelId())];"
                } else {
                    stmt = "\(model) model = [\(model.formatClassName()) modelWith\(prototype.formatClassName()):\(paramName) \(ir.modelId()):nil];"
                }
            }
        }
        
        return ObjC.CompoundStmt.ifStmt(condition: "[\(paramName) isKindOfClass:[\(prototype.formatClassName()) class]]", stmt: {
            [stmt,
             "return model;"]
        })
    }

    /*
    func generateCustomPropertyMapperStmt(flattenPath: [(Variable, String)],
                                          memberVariable: MemberVariable) -> (Variable, Variable)? {
        var custom: (Variable, Variable)?
        let variable = finalVariable(memberVariable: memberVariable)
        
        if let rewrittenName = memberVariable.3?.1 {
            custom = (rewrittenName, memberVariable.2)
        }
        
        if let flattenTuple = flattenPath.first(where: { (element) -> Bool in
            if element.0 == variable {
                return true
            }
            
            return false
        }) {
            custom = (flattenTuple.0, flattenTuple.1)
        }
        
        return custom
    }
 */
}

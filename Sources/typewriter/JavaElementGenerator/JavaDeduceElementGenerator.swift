//
//  JavaDeduceMapElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/13.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension JavaModelElementGenerator {
    func deduceTransformModelFromPrototypeMethod(ir: IR) -> Java.Methodz? {
        var isNeedGen = false
        var prototypeModelMap = [Type: (Type, Variable)]()
        
        ir.memberVariableList.forEach { (memberVariable) in
            _ = memberVariable.3?.2.map{
                switch $0 {
                case .prototype:
                    if let rewrittenType = memberVariable.3?.0 {
                        switch (memberVariable.1, rewrittenType) {
                        case (.ambiguous(let prototypeType), .ambiguous(let modelType)):
                            isNeedGen = true
                            prototypeModelMap[prototypeType] = (modelType, finalVariable(memberVariable: memberVariable))
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
        
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: "transformModelFromPrototype",
                           parameter: "Object prototype",
                           throwsz: nil,
                           returnType: "Object",
                           body: {
                            [Java.CompoundStmt.ifStmt(condition: "prototype == null", stmt: {
                                ["return null;"]
                            })] +
                                prototypeModelMap.map({(prototype: Type, model: (Type, Variable)) -> String in
                                    return generatePropertyModelMapWithPrototypeStmt(ir: ir,
                                                                                     paramName: "prototype",
                                                                                     prototype: prototype,
                                                                                     model: model.0,
                                                                                     variable: model.1)
                                }) +
                                ["return super.transformModelFromPrototype(prototype);"]
        })
    }

    func deduceCustomFieldsMapperMethod(ir: IR) -> Java.Methodz? {
        var variableTupleList: [(Variable, Variable)] = ir.makeFlattenMap()
            .flatMap{ element -> (Variable, Variable) in
                return (element.key, element.value)
            }
        
        variableTupleList.append(contentsOf: ir.makeReferenceFlattenMap()
            .flatMap({ (element) -> (Variable, Variable) in
                return (element.key, element.value)
            }))
        
        guard variableTupleList.count > 0 else {
            return nil
        }
        
        return Java.Method(annotations: ["@SuppressWarnings(\("unused".javaLiteral()))"],
                           accessControl: .publicz,
                           decoration: [.staticz],
                           generic: nil,
                           decl: "customFieldsMapper",
                           parameter: nil,
                           throwsz: nil,
                           returnType: "Map<String, String>",
                           body: {
                            ["Map<String, String> mapper = new HashMap<>();"] +
                                variableTupleList.map{"mapper.put(\($0.0.javaLiteral()), \($0.1.javaLiteral()));"} +
                            ["return mapper;"]
        })
    }
    
    func deducePrototypeConstructorMethod(ir: IR) -> Java.Methodz? {
        guard ir.isModelUnique() else {
            return nil
        }

        let typeConvertor = irTypeConvertor(forLanguage: .Java)
        let parameter = ir.memberVariableList.map { (memberVariable) -> String in
            let type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)
            
            return "\(typeConvertor(type)) \(variable)"
        }.joined(separator: ",\n\("public \(ir.desName)(".whitespaces())")
        
        let fieldsStmt = ir.memberVariableList.map { (memberVariable) -> String in
            let variable = finalVariable(memberVariable: memberVariable)
            return "this.\(variable) = \(variable);"
        }
        
        let dataflowCall = ir.isModelUnique() ? generateUndirectionalDataflowCall(ir: ir, entity: "this", identify: "this") : []
        
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: ir.desName,
                           parameter: parameter,
                           throwsz: nil,
                           returnType: nil,
                           body: {
                            fieldsStmt +
                            dataflowCall
        })
    }
    
    func deduceJSONConstructorMethod(ir: IR) -> Java.Methodz? {
        guard ir.isMemberVariableReadOnly() || ir.isContainEnum() else {
            return nil
        }

        let typeConvertor = irTypeConvertor(forLanguage: .Java)
        let parameter = ir.memberVariableList.map { (memberVariable) -> String in
            var type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)
            
            if ir.isMemberVariableEnum(memberVariable: memberVariable) {
                type = .string
            }
            
            return "\(typeConvertor(type)) \(variable)"
            }.joined(separator: ",\n\("public \(ir.desName)(".whitespaces())")
        
        
        let fieldsStmt = ir.memberVariableList.map { (memberVariable) -> String in
            let type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)

            if ir.isMemberVariableEnum(memberVariable: memberVariable) {
                return "this.\(variable) = \(typeConvertor(type)).\(enumFromJSONMethodName())(\(variable));"
            } else {
                return "this.\(variable) = \(variable);"
            }
        }
        
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: ir.desName,
                           parameter: parameter,
                           throwsz: nil,
                           returnType: nil,
                           body: {
                            fieldsStmt
        })
    }
    
    private func generatePropertyModelMapWithPrototypeStmt(ir: IR,
                                                           paramName: String,
                                                           prototype: Type,
                                                           model: Type,
                                                           variable: Variable) -> String {
        var stmt = "return new \(model)((\(prototype))\(paramName));"
        
        if let referenceIR = ir.jumpToReferenceIR(variable: variable) {
            if referenceIR.isModelUnique() {
                if ir.isModelUnique() {
                    stmt = "return new \(model)((\(prototype))\(paramName), this.\(ir.modelId()));"
                } else {
                    stmt = "return new \(model)((\(prototype))\(paramName), null);"
                }
            }
        }
        
        return Java.CompoundStmt.ifStmt(condition: "\(paramName) instanceof \(prototype)", stmt: {
            [stmt]
        })
    }
}

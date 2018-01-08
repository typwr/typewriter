//
//  JavaModelElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/13.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension IR {
    func findType(targetType: IRType) -> Bool {
        guard memberVariableList.contains(where: { (memberVariable) -> Bool in
            let type = finalType(memberVariable: memberVariable)
            if type == targetType {
                return true
            }
            
            return false
        }) else {
            return false
        }
        
        return true
    }
}

struct JavaModelElementGenerator {
    let ir: IR
    
    func enumFromJSONMethodName() -> String {
        return "fromJSONString"
    }
    
    func enumToJSONMethodName() -> String {
        return "toJSONString"
    }
    
    func generateJavaField(ir: IR, immutability: Java.Immutability, includeAnnotation: Bool) -> [Java.Field] {
        let convertor = irTypeConvertor(forLanguage: .Java)
        return ir.memberVariableList.map{ (memberVariable: MemberVariable) -> Java.Field in
            let type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)
            
            if variable == ir.modelId() {
                return (memberVariable.0,
                        includeAnnotation ? memberVariable.5 : nil,
                        Java.AccessControl.publicz,
                        [Java.FieldDecoration.none],
                        convertor(type),
                        variable)
            } else {
                return (memberVariable.0,
                        includeAnnotation ? memberVariable.5 : nil,
                        Java.AccessControl.publicz,
                        [immutability == Java.Immutability.immutable ? Java.FieldDecoration.final : Java.FieldDecoration.none],
                        convertor(type),
                        variable)
            }
        }
    }
    
    func generateElements() -> [Java.Element] {
        var modelMethods: [Java.Methodz] = []
        var component: [Java.Element]?
        
        for module in ir.generateModules {
            switch module {
            case .prototypeInitializer:
                modelMethods.append(generatePrototypeInitializer(ir: ir))
                
                if let deduceTransformModelFromPrototypeMethod = deduceTransformModelFromPrototypeMethod(ir: ir) {
                    modelMethods.append(deduceTransformModelFromPrototypeMethod)
                }
                
                if let deducePrototypeConstructorMethod = deducePrototypeConstructorMethod(ir: ir) {
                    modelMethods.append(deducePrototypeConstructorMethod)
                }
            case .jsonInitializer:
                modelMethods.append(generateJsonInitailizer(ir: ir))
                
                if let deduceJSONConstructorMethod = deduceJSONConstructorMethod(ir: ir) {
                    modelMethods.append(deduceJSONConstructorMethod)
                }
                
                if let deduceCustomMethod = deduceCustomFieldsMapperMethod(ir: ir) {
                    modelMethods.append(deduceCustomMethod)
                }
            case .prototypeInitializerPreprocess:
                modelMethods.append(generatePrototypeInitializerPreprocessMethod(ir: ir))
            case .mutableVersion:
                modelMethods.append(generateBuilderMethod(ir: ir))
                component = [generateBuilderClass(ir: ir)]
            case .equality:
                modelMethods.append(generateEqualsMethod(ir: ir))
            case .hash:
                modelMethods.append(generateHashCodeMethod(ir: ir))
            case .unidirectionalDataflow:
                modelMethods.append(generateUnidirectionalDataflowMethod(ir: ir))
            default:
                break
            }
        }
        
        return [Java.Element.package(package: generatePackage(ir: ir)),
                Java.Element.importz(files: generateImport(ir: ir)),
                Java.Element.classz(name: ir.desName,
                                    extends: ir.desInheriting,
                                    accessControl: .publicz,
                                    decoration: [.none],
                                    generic: nil,
                                    annotations: nil,
                                    component: component,
                                    interfaceComponent: ir.srcImplement.map{$0.map{($0, nil, nil)}},
                                    lambdaInitializer: nil,
                                    fileds: generateJavaField(ir: ir,
                                                              immutability: ir.isMemberVariableReadOnly() ? Java.Immutability.immutable : Java.Immutability.mutable,
                                                              includeAnnotation: true),
                                    methods: modelMethods)]
            .filter{(element : Java.Element) -> Bool in
                switch element {
                case .none:
                    return false
                default:
                    return true
                }
        }
    }
}

extension JavaModelElementGenerator {
    func generatePackage(ir: IR) -> String {
        return "...\(ir.desName)"
    }
    
    func generateImport(ir: IR) -> [String] {
        var res = [String]()
        
        if ir.inputFormat == .JSON, let _ = deduceCustomFieldsMapperMethod(ir: ir) {
            res.append("java.util.Map")
            res.append("java.util.HashMap")
        }
        
        if ir.findType(targetType: IRType.array(type: .any)) {
            res.append("java.util.List")
        }
        
        if ir.findType(targetType: IRType.map(keyType: .any, valueType: .any)) {
            res.append("java.util.Map")
        }
        
        if ir.findType(targetType: .date) {
            res.append("java.util.Date")
        }
        
        return res.removeDuplicate()
    }
}

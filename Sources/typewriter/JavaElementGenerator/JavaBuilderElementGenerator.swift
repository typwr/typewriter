//
//  JavaBuilderElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/13.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension JavaModelElementGenerator {
    func generateBuilderClass(ir: IR) -> Java.Element {
        return Java.Element.classz(name: builderClassName(),
                                   extends: nil,
                                   accessControl: .publicz,
                                   decoration: [.none],
                                   generic: nil,
                                   annotations: nil,
                                   component: nil,
                                   interfaceComponent: nil,
                                   lambdaInitializer: nil,
                                   fileds: generateBuilderField(ir: ir),
                                   methods: generateFieldMethods(ir: ir) + [generateBuildMethod(ir: ir)])
    }
    
    func generateBuilderMethod(ir: IR) -> Java.Methodz {
        let fieldsStmt = ir.memberVariableList.map { (memberVariable) -> String in
            let variable = finalVariable(memberVariable: memberVariable)
            return "builder.\(variable) = \(variable);"
        }
        
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: "builder",
                           parameter: nil,
                           throwsz: nil,
                           returnType: builderClassName(),
                           body: {
                            ["Builder builder = new Builder();"] +
                            fieldsStmt +
                            ["return builder;"]
        })
    }
    
    func builderClassName() -> String {
        return "Builder"
    }
    
    private func generateBuilderField(ir: IR) -> [Java.Field] {
        return generateJavaField(ir: ir,
                                 immutability: Java.Immutability.mutable,
                                 includeAnnotation: false)
    }
    
    private func generateFieldMethod(ir: IR, memberVariable: MemberVariable) -> Java.Methodz {
        let type = finalType(memberVariable: memberVariable)
        let variable = finalVariable(memberVariable: memberVariable)
        let typeConvertor = irTypeConvertor(forLanguage: .Java)
        
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: variable,
                           parameter: "\(typeConvertor(type)) \(variable)",
            throwsz: nil,
            returnType: builderClassName(),
            body: {
                ["this.\(variable) = \(variable);",
                 "return this;"]
        })
    }
    
    private func generateFieldMethods(ir: IR) -> [Java.Methodz] {
        return ir.memberVariableList.map{generateFieldMethod(ir: ir, memberVariable: $0)}
    }
    
    private func generateBuildMethod(ir: IR) -> Java.Methodz {
        let convetor = irTypeConvertor(forLanguage: .Java)
        
        let fieldStmt = ir.memberVariableList
            .map({ memberVariable -> String in
                let type = finalType(memberVariable: memberVariable)
    
                switch ir.inputFormat {
                case .JSON:
                    if ir.isMemberVariableEnum(memberVariable: memberVariable) {
                        return "\(convetor(type)).\(enumToJSONMethodName())(\(finalVariable(memberVariable: memberVariable)))"
                    }
                default:
                    break
                }
                
                return finalVariable(memberVariable: memberVariable)
            })
            .joined(separator: ",\n\("return new \(ir.desName)(".whitespaces())")
        
        let stmt = ir.inputFormat == .JSON ?
            (["\(ir.desName) model = new \(ir.desName)(\(fieldStmt));",
                generateUndirectionalDataflowCall(ir: ir, entity:"model", identify: "model").first!,
              "return model;"]) :
            ["return new \(ir.desName)(\(fieldStmt));"]
        
        return Java.Method(annotations: nil,
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: "build",
                           parameter: nil,
                           throwsz: nil,
                           returnType: ir.desName,
                           body: {
                            stmt
        })
    }
}

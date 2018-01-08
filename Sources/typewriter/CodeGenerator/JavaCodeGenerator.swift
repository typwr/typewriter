//
//  JavaCodeGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/6.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct JavaCodeGenerator: CodeGenerator {
    static func generateElements(ir: IR) -> [Java.Element] {
        return JavaModelElementGenerator(ir: ir).generateElements()
    }
    
    static func generate(ir: IR) -> [FileRepresent] {
        return [JavaRepresent(elements: generateElements(ir: ir), name: ir.desName)]
    }
}

extension Java.Element {
    fileprivate func mapElementToComponent(elements: [Java.Element]?) -> [RepresentComposite]? {
        return elements.flatMap{
            $0.flatMap{ (element: Java.Element) -> RepresentComposite? in
                switch element {
                case .none, .package, .importz, .lambdaInitliazer, .interface:
                    return nil
                case .classz(let name,
                             let extends,
                             let accessControl,
                             let decoration,
                             let generic,
                             let annotations,
                             let component,
                             let interfaceComponent,
                             let lambdaInitializer,
                             let fields,
                             let methods):
                    return Java.Class(name: name,
                                      extends: extends,
                                      accessControl: accessControl,
                                      decoration: decoration,
                                      generic: generic,
                                      annotations: annotations,
                                      component: mapElementToComponent(elements: component),
                                      interfaceComponent: interfaceComponent,
                                      lambdaInitializer: lambdaInitializer,
                                      fields: fields,
                                      methods: methods)
                case .enumz(let name,
                            let accessControl,
                            let decoration,
                            let annotations,
                            let component,
                            let interfaceComponent,
                            let caseVariable,
                            let fields,
                            let methods):
                    return Java.Enum(name: name,
                                     accessControl: accessControl,
                                     decoration: decoration,
                                     annotations: annotations,
                                     component: mapElementToComponent(elements: component),
                                     interfaceComponent: interfaceComponent,
                                     caseVariable: caseVariable,
                                     fields: fields,
                                     methods: methods)
                }
            }
        }
    }
    
    fileprivate func represent() -> [String] {
        switch self {
        case .none:
            return []
        case .package(let package):
            return [Java.SimpleDecl.packageDecl(decl: package)]
        case .importz(let files):
            return files.map{Java.SimpleDecl.importDecl(decl: $0)}
        case .lambdaInitliazer(let initliazer):
            return initliazer.map{Java.CompoundDecl.lambdaInitalizerDecl(initalizer: $0)}
        case .interface(let name,
                        let accessControl,
                        let generic,
                        let annotations,
                        let methods):
            return Java.Interface(name: name,
                                  accessControl: accessControl,
                                  generic: generic,
                                  annotations: annotations,
                                  methods: methods).represent()
        case .classz(let name,
                     let extends,
                     let accessControl,
                     let decoration,
                     let generic,
                     let annotations,
                     let component,
                     let interfaceComponent,
                     let lambdaInitializer,
                     let fields,
                     let methods):
            return Java.Class(name: name,
                              extends: extends,
                              accessControl: accessControl,
                              decoration: decoration,
                              generic: generic,
                              annotations: annotations,
                              component: mapElementToComponent(elements: component),
                              interfaceComponent: interfaceComponent,
                              lambdaInitializer: lambdaInitializer,
                              fields: fields,
                              methods: methods).represent()
        case .enumz(let name,
                    let accessControl,
                    let decoration,
                    let annotations,
                    let component,
                    let interfaceComponent,
                    let caseVariable,
                    let fields,
                    let methods):
            return Java.Enum(name: name,
                             accessControl: accessControl,
                             decoration: decoration,
                             annotations: annotations,
                             component: mapElementToComponent(elements: component),
                             interfaceComponent: interfaceComponent,
                             caseVariable: caseVariable,
                             fields: fields,
                             methods: methods).represent()
        }
    }
}

fileprivate struct JavaRepresent: FileRepresent {
    fileprivate var elements: [Java.Element]
    fileprivate var name: String
    
    fileprivate var representName: String {
        return name + ".java"
    }
    
    fileprivate func representEntity() -> String {
        let res = ([representInfo()] +
            elements.flatMap{$0.represent().joined(separator: "\n")})
            .representInFile()
        return res + "\n"
    }
}

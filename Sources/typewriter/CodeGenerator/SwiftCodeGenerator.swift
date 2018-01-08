//
//  SwiftCodeGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/3.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct SwiftCodeGenerator: CodeGenerator {
    static func generateElements(ir: IR) -> [Swift.Element] {
        return SwiftModelElementGenerator(ir: ir).generateElements()
    }
    
    static func generate(ir: IR) -> [FileRepresent] {
        return [SwiftRepresent(elements: generateElements(ir: ir), name: ir.desName)]
    }
}

extension Swift.Element {
    fileprivate func mapElementToComponent(elements: [Swift.Element]?) -> [RepresentComposite]? {
        return elements.flatMap{
            $0.flatMap{ (element: Swift.Element) -> RepresentComposite? in
                switch element {
                case .none, .importz, .globalDecl, .function, .protocolz:
                    return nil
                case .classz(let name,
                             let inherited,
                             let accessControl,
                             let decoration,
                             let generic,
                             let component,
                             let protocolComponent,
                             let typeDecl,
                             let memberVariable,
                             let funcz):
                    return Swift.Class(name: name,
                                       inherited: inherited,
                                       accessControl: accessControl,
                                       decoration: decoration,
                                       generic: generic,
                                       component: mapElementToComponent(elements: component),
                                       protocolComponent: protocolComponent,
                                       typeDecl: typeDecl,
                                       memberVariable: memberVariable,
                                       funcz: funcz)
                case .structz(let name,
                              let accessControl,
                              let generic,
                              let component,
                              let protocolComponent,
                              let typeDecl,
                              let memberVariable,
                              let funcz):
                    return Swift.Struct(name: name,
                                        accessControl: accessControl,
                                        generic: generic,
                                        component: mapElementToComponent(elements: component),
                                        protocolComponent: protocolComponent,
                                        typeDecl: typeDecl,
                                        memberVariable: memberVariable,
                                        funcz: funcz)
                case .enumz(let name,
                            let accessControl,
                            let decoration,
                            let generic,
                            let component,
                            let protocolComponent,
                            let typeDecl,
                            let globalVariable,
                            let caseVariable,
                            let funcz):
                    return Swift.Enum(name: name,
                                      accessControl: accessControl,
                                      decoration: decoration,
                                      generic: generic,
                                      component: mapElementToComponent(elements: component),
                                      protocolComponent: protocolComponent,
                                      typeDecl: typeDecl,
                                      globalVariable: globalVariable,
                                      caseVariable: caseVariable,
                                      funcz: funcz)
                case .extensionz(let name,
                                 let accessControl,
                                 let constraint,
                                 let component,
                                 let protocolComponent,
                                 let typeDecl,
                                 let memberVariable,
                                 let funcz):
                    return Swift.Extension(name: name,
                                           accessControl: accessControl,
                                           constraint: constraint,
                                           component: mapElementToComponent(elements: component),
                                           protocolComponent: protocolComponent,
                                           typeDecl: typeDecl,
                                           memberVariable: memberVariable,
                                           funcz: funcz)
                }
            }
        }
    }
    
    fileprivate func represent() -> [String] {
        switch self {
        case .none:
            return []
        case .importz(let files):
            return files.map{"import \($0)"}
        case .globalDecl(let globalDecl):
            return globalDecl.map{Swift.SimpleDecl.globalDecl(globalDecl: $0)}
        case .function(let functions):
            return functions.map{$0.represent()}
        case .classz(let name,
                     let inherited,
                     let accessControl,
                     let decoration,
                     let generic,
                     let component,
                     let protocolComponent,
                     let typeDecl,
                     let memberVariable,
                     let funcz):
            return Swift.Class(name: name,
                               inherited: inherited,
                               accessControl: accessControl,
                               decoration: decoration,
                               generic: generic,
                               component: mapElementToComponent(elements: component),
                               protocolComponent: protocolComponent,
                               typeDecl: typeDecl,
                               memberVariable: memberVariable,
                               funcz: funcz).represent()
        case .structz(let name,
                      let accessControl,
                      let generic,
                      let component,
                      let protocolComponent,
                      let typeDecl,
                      let memberVariable,
                      let funcz):
            return Swift.Struct(name: name,
                                accessControl: accessControl,
                                generic: generic,
                                component: mapElementToComponent(elements: component),
                                protocolComponent: protocolComponent,
                                typeDecl: typeDecl,
                                memberVariable: memberVariable,
                                funcz: funcz).represent()
        case .enumz(let name,
                    let accessControl,
                    let decoration,
                    let generic,
                    let component,
                    let protocolComponent,
                    let typeDecl,
                    let globalVariable,
                    let caseVariable,
                    let funcz):
            return Swift.Enum(name: name,
                              accessControl: accessControl,
                              decoration: decoration,
                              generic: generic,
                              component: mapElementToComponent(elements: component),
                              protocolComponent: protocolComponent,
                              typeDecl: typeDecl,
                              globalVariable: globalVariable,
                              caseVariable: caseVariable,
                              funcz: funcz).represent()
        case .extensionz(let name,
                         let accessControl,
                         let constraint,
                         let component,
                         let protocolComponent,
                         let typeDecl,
                         let memberVariable,
                         let funcz):
            return Swift.Extension(name: name,
                                   accessControl: accessControl,
                                   constraint: constraint,
                                   component: mapElementToComponent(elements: component),
                                   protocolComponent: protocolComponent,
                                   typeDecl: typeDecl,
                                   memberVariable: memberVariable,
                                   funcz: funcz).represent()
        case .protocolz(let name,
                        let accessControl,
                        let typeDecl,
                        let memberVariable,
                        let funcz):
            return Swift.Protocolz(name: name,
                                   accessControl: accessControl,
                                   typeDecl: typeDecl,
                                   memberVariable: memberVariable,
                                   funcz: funcz).represent()
        }
    }
}

fileprivate struct SwiftRepresent: FileRepresent {
    fileprivate var elements: [Swift.Element]
    fileprivate var name: String
    
    fileprivate var representName: String {
        return name + ".swift"
    }
    
    fileprivate func representEntity() -> String {
        let res = ([representInfo()] +
            elements.flatMap{$0.represent().joined(separator: "\n")})
            .representInFile()
        return res + "\n"
    }
}

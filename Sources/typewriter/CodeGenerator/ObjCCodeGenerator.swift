//
//  ObjCCodeGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/8/25.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct ObjCCodeGenerator : CodeGenerator {
    static func generateModelElementGenerator(ir: IR) -> ObjCModelElementGenerator {
        return ObjCModelElementGenerator(ir: ir)
    }
    
    static func generateFileRepresents(modelGenerator: ObjCModelElementGenerator) -> [FileRepresent] {
        let elements = modelGenerator.generateElements()
        return [ObjCHeaderRepresent(elements: elements, name: modelGenerator.ir.desName),
                ObjCImplementRepresent(elements: elements, name: modelGenerator.ir.desName)]
    }
    
    static func generate(ir: IR) -> [FileRepresent] {
        return generateFileRepresents(modelGenerator: generateModelElementGenerator(ir: ir))
    }
}

fileprivate extension ObjC.Element {
    fileprivate func representInHeader() -> [String] {
        switch self {
        case .none:
            return []
        case .importz(let files):
            return [ObjC.Preprocess.importz(file: files[0])]
        case .classHint(let classHint):
            return classHint.map{ObjC.SimpleDecl.classHintDecl(classHint: $0)}
        case .macro(let macro):
            return macro.map{ObjC.Preprocess.macro(macro: $0)}
        case .globalDecl(let globalDecl):
            return globalDecl.map{ObjC.SimpleDecl.globalDecl(globalDecl: $0)}
        case.function(let functions):
            return functions.filter{$0.0 == .publicMethod}.map{$0.1.methodDecl()}
        case .classz(let name, let inherited, let protocols, let properties, let methods):
            return ObjC.Classz(name: name,
                               inherited: inherited,
                               protocols: protocols,
                               properties: properties,
                               methods: methods).representInHeader()
        case .category(let className, let categoryName, let properties, let methods):
            return ObjC.Category(className: className,
                                 categoryName: categoryName,
                                 properties: properties,
                                 methods: methods).representInHeader()
        case .enumz(let name, let caseVariable):
            return ObjC.NSEnum(name: name, caseVariable: caseVariable).represent()
        case .optionz(let name, let option):
            return ObjC.NSOptions(name: name, option: option).represent()
        case .structz(let name, let fileds):
            return ObjC.Struct(name: name, fileds: fileds).represent()
        }
    }
    
    fileprivate func representInImplementation() -> [String] {
        switch self {
        case .none:
            return []
        case .importz(let files):
            var ruleOutSuperClass = files
            ruleOutSuperClass.removeFirst()
            return ruleOutSuperClass.map{ObjC.Preprocess.importz(file: $0)}
        case .classHint:
            return []
        case .macro:
            return []
        case .globalDecl(let globalDecl):
            return globalDecl.map{ObjC.SimpleDecl.globalDecl(globalDecl: $0)}
        case.function(let functions):
            return functions.map{$0.1.methodImpl()}
        case .classz(let name, _, let protocols, _, let methods):
            return ObjC.Classz(name: name,
                               inherited: nil,
                               protocols: protocols,
                               properties: [],
                               methods: methods).representInImplementation()
        case .category(let className, let categoryName, let properties, let methods):
            return ObjC.Category(className: className,
                                 categoryName: categoryName,
                                 properties: properties,
                                 methods: methods).representInImplementation()
        case .enumz:
            return []
        case .optionz:
            return []
        case .structz(let name, let fileds):
            return ObjC.Struct(name: name, fileds: fileds).represent()
        }
    }
}

fileprivate struct ObjCHeaderRepresent: FileRepresent {
    fileprivate var elements: [ObjC.Element]
    fileprivate var name: String
    
    fileprivate var representName: String {
        return name + ".h"
    }
    
    fileprivate func representEntity() -> String {
        let res = ([representInfo()] +
            elements.flatMap{$0.representInHeader().joined(separator: "\n")})
            .representInFile()
        return res + "\n"
    }
}

fileprivate struct ObjCImplementRepresent: FileRepresent {
    fileprivate var elements: [ObjC.Element]
    fileprivate var name: String
    
    fileprivate var representName: String {
        return name + ".m"
    }
    
    fileprivate func representEntity() -> String {
        let res = ([representInfo()] +
            elements.flatMap{$0.representInImplementation().joined(separator: "\n")})
            .representInFile()
        return res + "\n"
    }
}

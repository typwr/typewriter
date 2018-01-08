//
//  ObjC.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/13.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct ObjC {
    
    enum MemoryAssignment: String {
        case assign = "assign"
        case weak = "weak"
        case copy = "copy"
        case strong = "strong"
    }
    
    enum Immutability: String {
        case immutable = "readonly"
        case mutable = "readwrite"
    }
    
    enum Nullablez: String {
        case nullable = "nullable"
        case nonnull = "nonnull"
        
        static func from(nullable: Nullable) -> Nullablez {
            switch nullable {
            case .required, .almost:
                return .nullable
            case .optional:
                return .nonnull
            }
        }
    }
    
    enum MethodVisibility {
        case publicMethod
        case privateMethod
    }
    
    typealias Property = (Comments?, Immutability, MemoryAssignment, Nullablez, Type, Variable)
    typealias Protocolz = (String, [ObjC.Methodz])
    typealias Option = (Variable, String)
    typealias CaseVariable = (Variable, Variable?)
    typealias Fileds = [(Type, Variable)]
    
    enum SimpleStmt: String {
        case leftBracket = "{"
        case rightBracket = "}"
        case leftParentheses = "("
        case rightParentheses = ")"
        case brk = "break"
        case ret = "return"
        case cont = "continue"
        case def = "default"
        case leftComment = "/**"
        case rightComment = " */"
        
        func plusSemicolon() -> String {
            return rawValue + ";"
        }
        
        func plusColon() -> String {
            return rawValue + ":"
        }
    }
    
    struct CompoundStmt {
        static func scopeStmt(stmt: () -> [String]) -> String {
            return [SimpleStmt.leftBracket.rawValue,
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func ifStmt(condition: String, stmt: () -> [String]) -> String {
            return ["if (\(condition)) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func ifElseStmt(condition: String, ifStmt: @escaping () -> [String]) -> (() -> [String]) -> String {
            return { elseStmt in
                ["if (\(condition)) {",
                    -->ifStmt,
                    "\(SimpleStmt.rightBracket.rawValue) else \(SimpleStmt.leftBracket.rawValue)",
                    -->elseStmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
            }
        }
        
        static func forStmt(condition: String, stmt: () -> [String]) -> String {
            return ["for (\(condition)) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func doWhileStmt(condition: String, stmt: () -> [String]) -> String {
            return ["do \(SimpleStmt.leftBracket.rawValue)",
                    -->stmt,
                    "\(SimpleStmt.rightBracket.rawValue) while(\(condition))"].joined(separator: "\n")
        }
        
        static func whileStmt(condition: String, stmt: () -> [String]) -> String {
            return ["while (\(condition)) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func caseStmt(condition: String, stmt: () -> [String]) -> String {
            return ["case \(condition):",
                    -->stmt,
                    -->[SimpleStmt.brk.plusSemicolon()]].joined(separator: "\n")
        }
        
        static func defaultStmt(stmt: () -> [String]) -> String {
            return [SimpleStmt.def.plusColon(),
                    -->stmt,
                    -->[SimpleStmt.brk.plusSemicolon()]].joined(separator: "\n")
        }
        
        static func switchStmt(condition: String, stmt: () -> [String]) -> String {
            return ["switch (\(condition)) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func tryCatchStmt(tryStmt: @escaping () -> [String]) -> (() -> [String]) -> String {
            return { catchStmt in
                return ["@try \(SimpleStmt.leftBracket.rawValue)",
                    -->tryStmt,
                    "\(SimpleStmt.rightBracket.rawValue) @catch (NSException *exception) \(SimpleStmt.leftBracket.rawValue)",
                    -->catchStmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
            }
        }
        
        static func blockStmt(blockParam: [String], stmt: () -> [String]) -> String {
            return ["^" + (blockParam.count == 0 ? "()" : "(\(blockParam.joined(separator: ",")))" + "{"),
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
    }
    
    struct SimpleDecl {
        static func interDecl(className: String, superClassName: String) -> String {
            return "@interface " + className + " : " + superClassName
        }
        
        static func categoryInterDecl(className: String, categoryName: String?) -> String {
            return "@interface " + className + " (" + (categoryName == nil ? "" : categoryName!) + ")"
        }
        
        static func categoryImplDecl(className: String, categoryName: String?) -> String {
            return "@implementation " + className + " (" + (categoryName == nil ? "" : categoryName!) + ")"
        }
        
        static func protocolDecl(className: String, superClassName:String, protocolName: [String]) -> String {
            return interDecl(className: className, superClassName: superClassName) +
                "<" + protocolName.joined(separator: ", ") + ">"
        }
        
        static func propertyDecl(decl: Property) -> [String] {
            let property = "@property (" +
                "nonatomic, " +
                decl.1.rawValue + ", " +
                decl.2.rawValue +
                (decl.3 == Nullablez.nonnull ? ") " :  ", \(Nullablez.nullable.rawValue)) ") +
                decl.4 +
                (ObjC.isReferenceType(type: decl.4) ? "" : " ") +
                decl.5 +
                ";"
            
            if let comments = decl.0 {
                return [SimpleStmt.leftComment.rawValue,
                        comments.map{" * " + $0}.joined(separator: "/n"),
                        SimpleStmt.rightComment.rawValue,
                        property]
            } else {
                return [property]
            }
        }
        
        static func implDecl(className: String) -> String {
            return "@implementation " + className
        }
        
        static func endDecl() -> String {
            return "@end"
        }
        
        static func classHintDecl(classHint: String) -> String {
            return "@class " + classHint + ";"
        }
        
        static func globalDecl(globalDecl: String) -> String {
            return globalDecl
        }
    }
    
    struct CompoundDecl {
        static func enumDecl(enumName: String, decl: @autoclosure () -> [CaseVariable]) -> String {
            return ["typedef NS_ENUM(NSUInteger, \(enumName)) {",
                -->decl().map{($1 == nil) ? ($0 + ",") : ($0 + " = " + $1! + ",")},
                SimpleStmt.rightBracket.plusSemicolon()].joined(separator: "\n")
        }
        
        static func optionsDecl(optionsName: String, decl: @autoclosure () -> [Option]) -> String {
            return ["typedef NS_OPTIONS(NSUInteger, \(optionsName)) {",
                -->decl().map{$0 + " = 1 << " + $1 + ","},
                SimpleStmt.rightBracket.plusSemicolon()].joined(separator: "\n")
        }
        
        static func structDecl(structName: String, decl: @autoclosure () -> Fileds) -> String {
            return ["struct " + structName + " {",
                    -->decl().map{$0 + " " + $1 + ";"},
                    SimpleStmt.rightBracket.plusSemicolon()].joined(separator: "\n")
        }
    }
    
    static func Method(decl: String, impl: () -> [String]) -> ObjC.Methodz {
        return ObjC.Methodz(decl: decl, impl: impl())
    }
    
    struct Methodz {
        let decl: String
        let impl: [String]
        
        func methodDecl() -> String {
            return decl + ";"
        }
        
        func methodImpl() -> String {
            return [decl,
                    SimpleStmt.leftBracket.rawValue,
                    -->impl,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
    }
    
    struct Preprocess {
        static func importz(file: String) -> String {
            return "#import " + file
        }
        
        static func macro(macro: String) -> String {
            return macro
        }
    }
    
    static func isReferenceType(type: Type) -> Bool {
        return type.range(of: "*", options: .backwards) != nil
    }
    
    enum Element {
        case none
        case importz(files: [String])
        case classHint(classHint: [String])
        case macro(macro: [String])
        case globalDecl(globalDecl: [String])
        case function(functions: [(MethodVisibility, ObjC.Methodz)])
        case classz(name: String,
            inherited: String?,
            protocols: [Protocolz]?,
            properties: [Property],
            methods: [(MethodVisibility, ObjC.Methodz)])
        case category(className: String,
            categoryName: String?,
            properties: [Property]?,
            methods: [(MethodVisibility, ObjC.Methodz)])
        case enumz(name: String, caseVariable:[CaseVariable])
        case optionz(name: String, option:[Option])
        case structz(name: String, fileds: Fileds)
    }
    
    struct Classz {
        let name: String
        let inherited: String?
        let protocols: [Protocolz]?
        let properties: [Property]
        let methods: [(MethodVisibility, ObjC.Methodz)]
        
        func representInHeader() -> [String] {
            let superClass = inherited ?? "NSObject"
            var interfaceDecl: [String]
            
            if let protocolNames = protocols.map({$0.map{$0.0}}) {
                interfaceDecl = [ObjC.SimpleDecl.protocolDecl(className: name,
                                                              superClassName: superClass,
                                                              protocolName: protocolNames)]
            } else {
                interfaceDecl = [ObjC.SimpleDecl.interDecl(className: name,
                                                           superClassName: superClass)]
            }
            return interfaceDecl +
                properties
                    .flatMap(SimpleDecl.propertyDecl) +
                methods
                    .filter{$0.0 == .publicMethod}
                    .map{$0.1.methodDecl()} +
                [ObjC.SimpleDecl.endDecl()]
        }
        
        func representInImplementation() -> [String] {
            var classz = [ObjC.SimpleDecl.implDecl(className: name)] + methods.map{$1.methodImpl()}
            if let proto = protocols {
                classz = classz + proto.flatMap{(prot: ObjC.Protocolz) -> [String] in
                    return prot.1.map{$0.methodImpl()}
                }
            }
            return classz + [ObjC.SimpleDecl.endDecl()]
        }
    }
    
    struct Category {
        let className: String
        let categoryName: String?
        let properties: [Property]?
        let methods: [(MethodVisibility, ObjC.Methodz)]
        
        func representInHeader() -> [String] {
            guard let category = categoryName else { return [] }
            let categoryDecl = [ObjC.SimpleDecl.categoryInterDecl(className: className, categoryName: category)]
            if let extensionProperties = properties {
                return categoryDecl +
                    extensionProperties.flatMap(SimpleDecl.propertyDecl) +
                    methods.filter{$0.0 == .publicMethod}.map{$0.1.methodDecl()} +
                    [ObjC.SimpleDecl.endDecl()]
            } else {
                return categoryDecl +
                    methods.filter{$0.0 == .publicMethod}.map{$0.1.methodDecl()} +
                    [ObjC.SimpleDecl.endDecl()]
            }
        }
        
        func representInImplementation() -> [String] {
            if let categoryName = categoryName {
                return [ObjC.SimpleDecl.categoryImplDecl(className: className, categoryName: categoryName)] +
                    methods.map{$0.1.methodImpl()} +
                    [ObjC.SimpleDecl.endDecl()]
            } else {
                if let categoryProperties = properties {
                    return [ObjC.SimpleDecl.categoryInterDecl(className: className, categoryName: nil)] +
                        categoryProperties.flatMap(SimpleDecl.propertyDecl) +
                        methods.map{$0.1.methodDecl()} +
                        [ObjC.SimpleDecl.endDecl()]
                } else {
                    return [ObjC.SimpleDecl.categoryInterDecl(className: className, categoryName: categoryName)] +
                        methods.map{$0.1.methodDecl()} +
                        [ObjC.SimpleDecl.endDecl()]
                }
            }
        }
    }
    
    struct Struct {
        let name: String
        let fileds: Fileds
        
        func represent() -> [String] {
            return [CompoundDecl.structDecl(structName: name, decl: fileds)]
        }
    }
    
    struct NSEnum {
        let name: String
        let caseVariable: [CaseVariable]
        
        func represent() -> [String] {
            return [CompoundDecl.enumDecl(enumName: name, decl: caseVariable)]
        }
    }
    
    struct NSOptions {
        let name: String
        let option: [Option]
        
        func represent() -> [String] {
            return [CompoundDecl.optionsDecl(optionsName: name, decl: option)]
        }
    }
}

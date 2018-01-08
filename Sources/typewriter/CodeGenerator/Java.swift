//
//  Java.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/4.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct Java {
    enum AccessControl: String {
        case friendly = ""
        case publicz = "public "
        case protected = "protected "
        case privatez = "private "
    }
    
    enum Immutability: String {
        case immutable = "final "
        case mutable = ""
    }
    
    enum FieldDecoration: String {
        case none = ""
        case final = "final "
        case staticz = "static "
    }
    
    enum MethodDecoration: String {
        case none = ""
        case staticz = "static "
        case final = "final "
        case abstract = "abstract "
        case defaultz = "default "
        case synchronized = "synchronized "
        case native = "native "
    }
    
    enum ClassDecoration: String {
        case none = ""
        case staticz = "static "
        case final = "final "
        case abstract = "abstract "
    }
    
    enum EnumDecoration: String {
        case none = ""
        case staticz = "static "
    }
    
    enum LambdaInitializerDecoration: String {
        case none = ""
        case staticz = "static "
    }
    
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
    }
    
    typealias Generic = Type
    typealias LambdaInitalizer = ([LambdaInitializerDecoration], [String])
    typealias Field = (Comments?, Annotation?, AccessControl, [FieldDecoration], Type, Variable)
    typealias CaseVariable = Variable
    typealias InterfaceComponent = (Variable, Generic?, [Methodz]?)
    typealias Annotation = [String]
    
    struct CompoundStmt {
        
        static func scopeStmt(scope: () -> [String]) -> String {
            return [SimpleStmt.leftBracket.rawValue,
                    -->scope,
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
        
        static func whileStmt(condition: String, stmt: () -> [String]) -> String {
            return ["while (\(condition)) {",
                -->stmt,
                SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func doWhileStmt(condition: String, stmt: () -> [String]) -> String {
            return ["do \(SimpleStmt.leftBracket.rawValue)",
                -->stmt,
                "\(SimpleStmt.rightBracket.rawValue) while (\(condition))"].joined(separator: "\n")
        }
        
        static func caseStmt(condition: String, stmt: () -> [String]) -> String {
            return ["case \(condition):",
                -->stmt,
                SimpleStmt.brk.plusSemicolon()].joined(separator: "\n")
        }
        
        static func defaultStmt(stmt: () -> [String]) -> String {
            return ["\(SimpleStmt.def.rawValue):",
                -->stmt,
                SimpleStmt.brk.plusSemicolon()].joined(separator: "\n")
        }
        
        static func switchStmt(condition: String, stmt: () -> [String]) -> String {
            return ["switch \(condition) {",
                -->stmt,
                SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func tryCatchStmt(tryStmt: () -> [String],
                                 catchPattern: String,
                                 catchStmt: () -> [String]) -> String {
            return tryCatchFinallyStmt(tryStmt: tryStmt,
                                       catchPattern: catchPattern,
                                       catchStmt: catchStmt,
                                       finallyStmt: nil)
        }
        
        static func tryCatchFinallyStmt(tryStmt: () -> [String],
                                        catchPattern: String,
                                        catchStmt: () -> [String],
                                        finallyStmt: (() -> [String])?) -> String {
            var stmt = ["try \(SimpleStmt.leftBracket.rawValue)",
                -->tryStmt,
                "\(SimpleStmt.rightBracket.rawValue) catch (\(catchPattern)) \(SimpleStmt.leftBracket.rawValue)",
                -->catchStmt]
            
            if let finallyStmt = finallyStmt {
                stmt = stmt +
                    ["\(SimpleStmt.rightBracket.rawValue) finally \(SimpleStmt.leftBracket.rawValue)",
                    -->finallyStmt,
                    SimpleStmt.rightBracket.rawValue]
            } else {
                stmt.append(SimpleStmt.rightBracket.rawValue)
            }
            
            return stmt.joined(separator: "\n")
        }
        
        static func simpleLambdaStmt(mutiplyCallDecl: Bool, call: String, body: String) -> String {
            if mutiplyCallDecl {
                return ["(\(call)) -> \(body)"].joined(separator: "\n")
            } else {
                return ["\(call) -> \(body)"].joined(separator: "\n")
            }
        }
        
        static func compoundLambdaStmt(call: String, body: () -> [String]) -> String {
            return ["(\(call)) -> \(SimpleStmt.leftBracket.rawValue)",
                -->body,
                SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func anonymousClassStmt(classInstance: String?,
                                       className: Variable,
                                       constructPara: String?,
                                       stmt: () -> [String]) -> [String] {
            var anonymousStmt = ""
            if let classInstance = classInstance {
                anonymousStmt += classInstance
                anonymousStmt += " = "
            }
            
            anonymousStmt += "new \(className)"
            if let constructPara = constructPara {
                anonymousStmt += "(\(constructPara))"
            } else {
                anonymousStmt += "()"
            }
            
            return ["\(anonymousStmt) \(SimpleStmt.leftBracket.rawValue)",
                -->stmt,
                SimpleStmt.rightBracket.plusSemicolon()]
        }
        
        static func innerClassStmt(name: Variable,
                                   extends: Variable?,
                                   accessControl: AccessControl,
                                   decoration: [ClassDecoration],
                                   generic: Generic?,
                                   annotations: Annotation,
                                   component: [RepresentComposite]?,
                                   interfaceComponent: [InterfaceComponent]?,
                                   lambdaInitializer: [LambdaInitalizer]?,
                                   fields: [Field]?,
                                   methods: [Methodz]?) -> [String] {
            return Class(name: name,
                         extends: extends,
                         accessControl: accessControl,
                         decoration: decoration,
                         generic: generic,
                         annotations: annotations,
                         component: component,
                         interfaceComponent: interfaceComponent,
                         lambdaInitializer: lambdaInitializer,
                         fields: fields,
                         methods: methods).represent()
        }
    }
    
    struct SimpleDecl {
        
        static func packageDecl(decl: String) -> String {
            return "package \(decl);"
        }
        
        static func importDecl(decl: String) -> String {
            return "import \(decl);"
        }
        
        static func genericDecl(decl: Generic?) -> String {
            if let declVariable = decl {
                return "<\(declVariable)>"
            }
            return ""
        }

        static func fieldDecl(decl: Field) -> String {
            let decoration = decl.3.map{$0.rawValue}.joined(separator: "")
            let annotation = annotationDecl(decl: decl.1)
            let field = "\(decl.2.rawValue)\(decoration)\(decl.4) \(decl.5);"
                        
            if let comments = decl.0 {
                return ([SimpleStmt.leftComment.rawValue,
                        comments.map{" * " + $0}.joined(separator: "/n"),
                        SimpleStmt.rightComment.rawValue] +
                        annotation +
                        [field]).joined(separator: "\n")
            } else {
                return (annotation +
                        [field]).joined(separator: "\n")
            }

        }
        
        static func caseVariableDecl(decl: [CaseVariable]?) -> [String] {
            guard let decl = decl else {
                return []
            }
            
            return ["\(decl.joined(separator: ", "));"]
        }
        
        static func annotationDecl(decl: Annotation?) -> [String] {
            guard let decl = decl else {
                return []
            }
            
            return decl
        }
    }
    
    struct CompoundDecl {
        
        static func lambdaInitalizerDecl(initalizer: LambdaInitalizer) -> String {
            return ["\(initalizer.0.map{$0.rawValue}.joined(separator: "")) \(SimpleStmt.leftBracket.rawValue))",
                -->initalizer.1,
                SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func interfaceDecl(name: Variable,
                                  accessControl: AccessControl,
                                  generic: Generic?,
                                  annotations: Annotation?,
                                  stmt: () -> [String]) -> [String] {
            return SimpleDecl.annotationDecl(decl: annotations) +
                ["\(accessControl.rawValue)interface\(SimpleDecl.genericDecl(decl: generic)) \(name) \(SimpleStmt.leftBracket.rawValue)",
                -->stmt,
                SimpleStmt.rightBracket.rawValue]
        }
        
        static func classDecl(name: Variable,
                              extends: Variable?,
                              accessControl: AccessControl,
                              decoration: [ClassDecoration],
                              generic: Generic?,
                              annotations: Annotation?,
                              interfaceComponent: [InterfaceComponent]?,
                              stmt: [String]?) -> [String] {
            var decl = "\(accessControl.rawValue)\(decoration.map{$0.rawValue}.joined(separator: ""))class\(SimpleDecl.genericDecl(decl: generic)) \(name)"
            
            if let extends = extends {
                decl += " extends \(extends)"
            }
            
            if let interface = interfaceComponent {
                decl += " implements \(interface.map{"\($0.0)\(SimpleDecl.genericDecl(decl: $0.1))"}.joined(separator: ""))"
            }
            
            if let body = stmt {
                return SimpleDecl.annotationDecl(decl: annotations) +
                    ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    -->body,
                    SimpleStmt.rightBracket.rawValue]
            } else {
                return SimpleDecl.annotationDecl(decl: annotations) +
                    ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    SimpleStmt.rightBracket.rawValue]
            }
        }
        
        static func enumDecl(name: Variable,
                             accessControl: AccessControl,
                             decoration: [EnumDecoration],
                             annotations: Annotation?,
                             interfaceComponent: [InterfaceComponent]?,
                             stmt: [String]?) -> [String] {
            var decl = "\(accessControl.rawValue)\(decoration.map{$0.rawValue}.joined(separator: ""))enum \(name)"
            
            if let interface = interfaceComponent {
                decl += " implements \(interface.map{"\($0.0)\(SimpleDecl.genericDecl(decl: $0.1))"}.joined(separator: ""))"
            }
            
            if let body = stmt {
                return SimpleDecl.annotationDecl(decl: annotations) +
                    ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    -->body,
                    SimpleStmt.rightBracket.rawValue]
            } else {
                return SimpleDecl.annotationDecl(decl: annotations) +
                    ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    SimpleStmt.rightBracket.rawValue]
            }
        }
    }
    
    struct Methodz {
        let annotations: Annotation?
        let accessControl: AccessControl
        let decoration: [MethodDecoration]
        let generic: Generic?
        let decl: String
        let parameter: String?
        let throwsz: String?
        let returnType: Type?
        let body: [String]?
        func represent() -> String {
            var wholeDecl = "\(accessControl.rawValue)\(decoration.map{$0.rawValue}.joined(separator: ""))\(SimpleDecl.genericDecl(decl: generic))"
            
            if let returnType = returnType  {
                wholeDecl += "\(returnType) "
            }
            
            wholeDecl += decl
            
            if let parameter = parameter {
                wholeDecl += "(\(parameter))"
            } else {
                wholeDecl += "()"
            }
            
            if let body = body {
                return (SimpleDecl.annotationDecl(decl: annotations) +
                    ["\(wholeDecl) \(SimpleStmt.leftBracket.rawValue)",
                        -->body,
                        SimpleStmt.rightBracket.rawValue]).joined(separator: "\n")
            } else {
                return wholeDecl
            }
        }
    }
    
    static func Method(annotations: Annotation?,
                       accessControl: AccessControl,
                       decoration: [MethodDecoration],
                       generic: Generic?,
                       decl: String,
                       parameter: String?,
                       throwsz: String?,
                       returnType: Type?,
                       body: () -> [String]?) -> Methodz {
        return Methodz(annotations: annotations,
                       accessControl: accessControl,
                       decoration: decoration,
                       generic: generic,
                       decl: decl,
                       parameter: parameter,
                       throwsz: throwsz,
                       returnType: returnType,
                       body: body())
    }
    
    fileprivate static func injectInterfaceComponent(methods: inout [Methodz]?, interfaceComponent: [InterfaceComponent]?) {
        if let interfaceComponent = interfaceComponent {
            var injectingMethod = [Methodz]()
            
            interfaceComponent.forEach() { (name, generic, method) in
                if let couldInjectMethod = method {
                    injectingMethod += couldInjectMethod
                }
            }

            if methods != nil {
                methods! += injectingMethod
            }
        }
    }
    
    enum Element {
        case none
        case package(package: String)
        case importz(files: [String])
        case lambdaInitliazer(initliazer: [LambdaInitalizer])
        case interface(name: Variable,
            accessControl: AccessControl,
            generic: Generic?,
            annotations: Annotation?,
            methods: [Methodz])
        case classz(name: Variable,
            extends: Variable?,
            accessControl: AccessControl,
            decoration: [ClassDecoration],
            generic: Generic?,
            annotations: Annotation?,
            component: [Element]?,
            interfaceComponent: [InterfaceComponent]?,
            lambdaInitializer: [LambdaInitalizer]?,
            fileds: [Field]?,
            methods: [Methodz]?)
        case enumz(name: Variable,
            accessControl: AccessControl,
            decoration: [EnumDecoration],
            annotations: Annotation?,
            component: [Element]?,
            interfaceComponent: [InterfaceComponent]?,
            caseVariable: [CaseVariable]?,
            fields: [Field]?,
            methods: [Methodz]?)
    }
    
    struct Class: RepresentComposite {
        let name: Variable
        let extends: Variable?
        let accessControl: AccessControl
        let decoration: [ClassDecoration]
        let generic: Generic?
        let annotations: Annotation?
        var component: [RepresentComposite]?
        let interfaceComponent: [InterfaceComponent]?
        let lambdaInitializer: [LambdaInitalizer]?
        let fields: [Field]?
        var methods: [Methodz]?
        
        init(name: Variable,
             extends: Variable?,
             accessControl: AccessControl,
             decoration: [ClassDecoration],
             generic: Generic?,
             annotations: Annotation?,
             component: [RepresentComposite]?,
             interfaceComponent: [InterfaceComponent]?,
             lambdaInitializer: [LambdaInitalizer]?,
             fields: [Field]?,
             methods: [Methodz]?) {
            self.name = name
            self.extends = extends
            self.accessControl = accessControl
            self.decoration = decoration
            self.generic = generic
            self.annotations = annotations
            self.component = component
            self.interfaceComponent = interfaceComponent
            self.lambdaInitializer = lambdaInitializer
            self.fields = fields
            self.methods = methods
            Java.injectInterfaceComponent(methods: &self.methods, interfaceComponent: self.interfaceComponent)
        }
        
        func represent() -> [String] {
            let componentStmt = component.map{$0.map{$0.represent().joined(separator: "\n")}}
            let lambdaInitializerStmt = lambdaInitializer.map{$0.map{CompoundDecl.lambdaInitalizerDecl(initalizer: $0)}}
            let fieldsStmt = fields.map{$0.map{SimpleDecl.fieldDecl(decl: $0)}}
            let methodStmt = methods.map{$0.map{$0.represent()}}
            let stmt = plus(left: plus(left: plus(left: lambdaInitializerStmt, right: fieldsStmt), right: methodStmt), right:  componentStmt)
            return CompoundDecl.classDecl(name: name,
                                          extends: extends,
                                          accessControl: accessControl,
                                          decoration: decoration,
                                          generic: generic,
                                          annotations: annotations,
                                          interfaceComponent: interfaceComponent,
                                          stmt: stmt)
        }
    }
    
    struct Enum: RepresentComposite {
        let name: Variable
        let accessControl: AccessControl
        let decoration: [EnumDecoration]
        let annotations: Annotation?
        var component: [RepresentComposite]?
        let interfaceComponent: [InterfaceComponent]?
        let caseVariable: [CaseVariable]?
        let fields: [Field]?
        var methods: [Methodz]?
        
        init(name: Variable,
             accessControl: AccessControl,
             decoration: [EnumDecoration],
             annotations: Annotation?,
             component: [RepresentComposite]?,
             interfaceComponent: [InterfaceComponent]?,
             caseVariable: [CaseVariable]?,
             fields: [Field]?,
             methods: [Methodz]?) {
            self.name = name
            self.accessControl = accessControl
            self.decoration = decoration
            self.annotations = annotations
            self.component = component
            self.interfaceComponent = interfaceComponent
            self.caseVariable = caseVariable
            self.fields = fields
            self.methods = methods
            Java.injectInterfaceComponent(methods: &self.methods, interfaceComponent: self.interfaceComponent)
        }
        
        func represent() -> [String] {
            let componentStmt = component.map{$0.map{$0.represent().joined(separator: "\n")}}
            let caseVariableStmt = SimpleDecl.caseVariableDecl(decl: caseVariable)
            let fieldsStmt = fields.map{$0.map{SimpleDecl.fieldDecl(decl: $0)}}
            let methodStmt = methods.map{$0.map{$0.represent()}}
            let stmt = plus(left: plus(left: plus(left: caseVariableStmt, right: fieldsStmt), right: methodStmt), right:  componentStmt)
            return CompoundDecl.enumDecl(name: name,
                                         accessControl: accessControl,
                                         decoration: decoration,
                                         annotations: annotations,
                                         interfaceComponent: interfaceComponent,
                                         stmt: stmt)
        }
    }
    
    struct Interface {
        let name: Variable
        let accessControl: AccessControl
        let generic: Generic?
        let annotations: Annotation?
        let methods: [Methodz]
        
        func represent() -> [String] {
            return CompoundDecl.interfaceDecl(name: name,
                                              accessControl: accessControl,
                                              generic: generic,
                                              annotations: annotations,
                                              stmt: {
                return methods.flatMap{$0.represent()}
            })
        }
    }
}

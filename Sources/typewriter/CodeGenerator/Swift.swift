//
//  Swift.swift
//  typewriter
//
//  Created by mrriddler on 2017/8/30.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct Swift {
    enum AccessControl: String {
        case none = ""
        case openz = "open "
        case publicz = "public "
        case internalz = "internal "
        case fileprivatez = "fileprivate "
        case privatez = "private "
    }
    
    enum Immutability: String {
        case letz = "let "
        case varz = "var "
    }
    
    enum MemoryManagment: String {
        case weak = "weak "
        case unowned = "unowned "
    }
    
    enum Optional: String {
        case required = ""
        case almost = "!"
        case optional = "?"
        
        static func from(nullable: Nullable) -> Optional {
            switch nullable {
            case .required:
                return .required
            case .almost:
                return .almost
            case .optional:
                return .optional
            }
        }
    }
    
    enum FuncDecoration: String {
        case none = ""
        case override = "override "
        case final = "final "
        case staticz = "static "
        case classz = "class "
        case mutating = "mutating "
        case nonmutating = "nonmutating "
        case convenience = "convenience "
        case required = "required "
    }
    
    enum ClassDecoration: String {
        case none = ""
        case final = "final "
    }
    
    enum EnumDecoration: String {
        case none = ""
        case indirect = "indirect "
    }
    
    enum MemberVariableDecoration: String {
        case none = ""
        case lazy = "lazy "
        case final = "final "
        case staticz = "static "
    }
    
    enum AttributeDecoration: String {
        case none = ""
        case autoclosure = "@autoclosure "
        case nonescape = "@noescape "
    }
    
    enum OperatorType: String {
        case infix = "infix "
        case prefix = "prefix "
        case postfix = "postfix"
    }
    
    enum Precedencegroup: String {
        case higherThan = "higherThan: "
        case lowerThan = "lowerThan: "
        case associativity = "associativity: "
        case assignment = "assignment: "
    }
    
    typealias Generic = Type
    typealias CaseVariable = (Variable, Variable?)
    typealias GlobalVariable = (AccessControl, Variable, Variable)
    typealias MemberVariable = (Comments?, AccessControl, [MemberVariableDecoration], Immutability, Optional, Type, Variable)
    typealias ProtocolComponent = (String, [MemberVariable]?, [Funcz]?)
    
    enum SimpleStmt: String {
        case leftBracket = "{"
        case rightBracket = "}"
        case leftParentheses = "("
        case rightParentheses = ")"
        case wh = "where"
        case brk = "break"
        case ret = "return"
        case cont = "continue"
        case def = "default"
        case leftComment = "/**"
        case rightComment = " */"
    }
    
    struct CompoundStmt {
        
        static func scopeStmt(scope: () -> [String]) -> String {
            return [SimpleStmt.leftBracket.rawValue,
                    -->scope,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func ifStmt(condition: String, stmt: () -> [String]) -> String {
            return ["if \(condition) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func ifElseStmt(condition: String, ifStmt: @escaping () -> [String]) -> (() -> [String]) -> String {
            return { elseStmt in
                ["if \(condition) {",
                    -->ifStmt,
                    "\(SimpleStmt.rightBracket.rawValue) else \(SimpleStmt.leftBracket.rawValue)",
                    -->elseStmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
            }
        }
        
        static func guardStmt(condition: String, elseStmt: () -> [String]) -> String {
            return ["guard \(condition) else \(SimpleStmt.leftBracket.rawValue)",
                    -->elseStmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func forStmt(condition: String, stmt: () -> [String]) -> String {
            return ["for \(condition) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func whileStmt(condition: String, stmt: () -> [String]) -> String {
            return ["while \(condition) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func repeatWhileStmt(condition: String, stmt: () -> [String]) -> String {
            return ["repeat \(SimpleStmt.leftBracket.rawValue)",
                    -->stmt,
                    "\(SimpleStmt.rightBracket.rawValue) while \(condition)"].joined(separator: "\n")
        }
        
        static func caseStmt(condition: String, stmt: () -> [String]) -> String {
            return ["case \(condition):",
                    -->stmt].joined(separator: "\n")
        }
        
        static func defaultStmt(stmt: () -> [String]) -> String {
            return ["\(SimpleStmt.def.rawValue):",
                    -->stmt].joined(separator: "\n")
        }
        
        static func switchStmt(condition: String, stmt: () -> [String]) -> String {
            return ["switch \(condition) {",
                    -->stmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func doCatchStmt(tryCondition: String, catchPattern: String, catchStmt: () -> [String]) -> String {
            return ["do \(SimpleStmt.leftBracket.rawValue)",
                    -->["try \(tryCondition)"],
                    "\(SimpleStmt.rightBracket.rawValue) catch \(catchPattern) \(SimpleStmt.leftBracket.rawValue)",
                    -->catchStmt,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func simpleClosureStmt(call: String, body: () -> [String]) -> String {
            return ["\(call)\(SimpleStmt.leftBracket.rawValue) \(body) \(SimpleStmt.rightBracket.rawValue)"].joined(separator: "\n")
        }
        
        static func compoundClosureStmt(call: String, parameters: String, returnType: String?, body: () -> [String]) -> String {
            if let noOmitType = returnType {
                return ["\(call)\(SimpleStmt.leftBracket.rawValue)\(SimpleStmt.leftParentheses.rawValue) \(parameters) \(SimpleStmt.rightParentheses.rawValue) -> \(noOmitType) in",
                        -->body,
                        SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
            } else {
                return ["\(call).\(SimpleStmt.leftBracket.rawValue)\(SimpleStmt.leftParentheses.rawValue) \(parameters) \(SimpleStmt.rightParentheses.rawValue)",
                    -->body,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
            }
        }
    }
    
    struct SimpleDecl {
        
        static func operatorDecl(type: OperatorType, decl: String) -> String {
            return ["\(type.rawValue) \(decl)"].joined(separator: "\n")
        }
        
        static func typealiasDecl(decl: String) -> String {
            return ["typealias \(decl)"].joined(separator: "\n")
        }
        
        static func associatedtypeDecl(decl: String) -> String {
            return ["associatedtype \(decl)"].joined(separator: "\n")
        }
        
        static func genericDecl(decl: Generic?) -> String {
            if let declVariable = decl {
                return "<\(declVariable)>"
            }
            return ""
        }
        
        static func caseVariableDecl(decl: CaseVariable) -> String {
            if let rhs = decl.1 {
                return "case \(decl.0) = \(rhs)"
            } else {
                return "case \(decl.0)"
            }
        }
        
        static func globalVariableDecl(decl: GlobalVariable) -> String {
            return "\(decl.0)static let \(decl.1) = \(decl.2)"
        }
        
        static func memberVariableDecl(decl: MemberVariable) -> String {
            let decoration = decl.2.map{$0.rawValue}.joined(separator: "")
            let memberVariable = "\(decl.1.rawValue)\(decoration)\(decl.3.rawValue)\(decl.6): \(decl.5)\(decl.4.rawValue)"
            
            if let comments = decl.0 {
                return [SimpleStmt.leftComment.rawValue,
                        comments.map{" * " + $0}.joined(separator: "/n"),
                        SimpleStmt.rightComment.rawValue,
                        memberVariable].joined(separator: "\n")
            } else {
                return memberVariable
            }
        }
        
        static func globalDecl(globalDecl: String) -> String {
            return globalDecl
        }
    }
    
    struct CompoundDecl {
        
        static func precedencegroupDecl(decl: String, stmt: [Precedencegroup: String]) -> String {
            return ["precedencegroup \(decl) \(SimpleStmt.leftBracket.rawValue)",
                    -->Array(stmt.keys.map{"\($0.rawValue)\(String(describing: stmt[$0]))"}),
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
        }
        
        static func deinitDecl(stmt: () -> [String]) -> Funcz {
            return Funcz(accessControl: .none,
                         decoration: [],
                         generic: nil,
                         constraint: nil,
                         decl: "deinit",
                         parameter: nil,
                         throwing: false,
                         returnType: nil,
                         body: stmt())
        }
        
        static func getDecl(stmt: () -> [String]) -> Funcz {
            return Funcz(accessControl: .none,
                         decoration: [],
                         generic: nil,
                         constraint: nil,
                         decl: "get",
                         parameter: nil,
                         throwing: false,
                         returnType: nil,
                         body: stmt())
        }
        
        static func setDecl(decl: String, stmt: () -> [String]) -> Funcz {
            return Funcz(accessControl: .none,
                         decoration: [],
                         generic: nil,
                         constraint: nil,
                         decl: "set(\(decl))",
                         parameter: nil,
                         throwing: false,
                         returnType: nil,
                         body: stmt())
        }
        
        static func willSetDecl(decl: String, stmt: () -> [String]) -> Funcz {
            return Funcz(accessControl: .none,
                         decoration: [],
                         generic: nil,
                         constraint: nil,
                         decl: "willSet(\(decl))",
                         parameter: nil,
                         throwing: false,
                         returnType: nil,
                         body: stmt())
        }
        
        static func didSetDecl(decl: String, stmt: () -> [String]) -> Funcz {
            return Funcz(accessControl: .none,
                         decoration: [],
                         generic: nil,
                         constraint: nil,
                         decl: "didSet(\(decl))",
                         parameter: nil,
                         throwing: false,
                         returnType: nil,
                         body: stmt())
        }
        
        static func subscriptDecl(decl: String, stmt: () -> [String]) -> Funcz {
            return Funcz(accessControl: .none,
                         decoration: [],
                         generic: nil,
                         constraint: nil,
                         decl: "subscript (\(decl))",
                         parameter: nil,
                         throwing: false,
                         returnType: nil,
                         body: stmt())
        }
        
        static func overrideVarDecl(name: String, decoration: [FuncDecoration], type: Type, stmt: () -> [String]) -> Funcz {
            return Funcz(accessControl: .none,
                         decoration: decoration,
                         generic: nil,
                         constraint: nil,
                         decl: "var \(name): \(type)",
                         parameter: nil,
                         throwing: false,
                         returnType: nil,
                         body: stmt())
        }
        
        static func initializerDecl(accessControl: AccessControl,
                                    decoration: [FuncDecoration],
                                    optional: Optional,
                                    parameter: String,
                                    throwing: Bool,
                                    stmt: () -> [String] ) -> Funcz {
            return Funcz(accessControl: accessControl,
                         decoration: decoration,
                         generic: nil,
                         constraint: nil,
                         decl: optional == .optional ? "init?" : "init",
                         parameter: parameter,
                         throwing: throwing,
                         returnType: nil,
                         body: stmt())
        }
        
        static func classDecl(name: Variable,
                              inherited: Variable?,
                              accessControl: AccessControl,
                              decoration: [ClassDecoration],
                              generic: Generic?,
                              protocolComponent: [ProtocolComponent]?,
                              stmt: [String]?) -> [String] {
            var superClass = ""
            if let inherited = inherited {
                superClass.append(": \(inherited)")
            }
            if let protocolName = protocolComponent {
                if superClass.isEmpty {
                    superClass.append(": ")
                } else {
                    superClass.append(", ")
                }
                superClass.append(protocolName.map{$0.0}.joined(separator: ", "))
            }
            
            let decl = "\(accessControl.rawValue)\(decoration.map{$0.rawValue}.joined(separator: ""))class \(name)\(SimpleDecl.genericDecl(decl: generic))\(superClass)"
            
            if let body = stmt {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                        -->body,
                        SimpleStmt.rightBracket.rawValue]
            } else {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                        SimpleStmt.rightBracket.rawValue]
            }
        }
        
        static func structDecl(name: String,
                               accessControl: AccessControl,
                               generic: Generic?,
                               protocolComponent: [ProtocolComponent]?,
                               stmt: [String]?) -> [String] {
            var conformFrom = ""
            if let protocolName = protocolComponent {
                if conformFrom.isEmpty {
                    conformFrom.append(": ")
                }
                conformFrom.append(protocolName.map{$0.0}.joined(separator: ", "))
            }

            let decl = "\(accessControl.rawValue)struct \(name)\(SimpleDecl.genericDecl(decl: generic))\(conformFrom)"

            if let body = stmt {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                        -->body,
                        SimpleStmt.rightBracket.rawValue]
            } else {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                        SimpleStmt.rightBracket.rawValue]
            }
        }
        
        static func enumDecl(name: String,
                             accessControl: AccessControl,
                             decoration: [EnumDecoration],
                             generic: Generic?,
                             protocolComponent: [ProtocolComponent]?,
                             stmt: [String]?) -> [String] {
            var conformFrom = ""
            if let protocolName = protocolComponent {
                if conformFrom.isEmpty {
                    conformFrom.append(": ")
                }
                conformFrom.append(protocolName.map{$0.0}.joined(separator: ", "))
            }
            
            let decl = "\(accessControl.rawValue)\(decoration.map{$0.rawValue}.joined(separator: ""))enum \(name)\(SimpleDecl.genericDecl(decl: generic))\(conformFrom)"
            
            if let body = stmt {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    -->body,
                    SimpleStmt.rightBracket.rawValue]
            } else {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    SimpleStmt.rightBracket.rawValue]
            }
        }
        
        static func extensionDecl(name: String,
                                  accessControl: AccessControl,
                                  constraint: String?,
                                  protocolComponent: [ProtocolComponent]?,
                                  stmt: [String]?) -> [String] {
            var decl = "\(accessControl.rawValue)extension \(name)"
            if let conformFrom = constraint {
                decl.append("\(SimpleStmt.wh.rawValue) \(conformFrom)")
            } else if let protocolName = protocolComponent {
                decl.append(": \(protocolName.map{$0.0}.joined(separator: ", "))")
            } else {}
            
            if let body = stmt {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    -->body,
                    SimpleStmt.rightBracket.rawValue]
            } else {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    SimpleStmt.rightBracket.rawValue]
            }
        }
        
        static func protocolDecl(name: String,
                                 accessControl: AccessControl,
                                 stmt: [String]?) -> [String] {
            
            let decl = "\(accessControl.rawValue)protocol \(name)"
            
            if let body = stmt {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    -->body,
                    SimpleStmt.rightBracket.rawValue]
            } else {
                return ["\(decl) \(SimpleStmt.leftBracket.rawValue)",
                    SimpleStmt.rightBracket.rawValue]
            }
        }
    }
    
    struct Funcz {
        let accessControl: AccessControl
        let decoration: [FuncDecoration]
        let generic: Generic?
        let constraint: String?
        let decl: String
        let parameter: String?
        let throwing: Bool
        let returnType: Type?
        let body: [String]?
        
        func represent() -> String {
            let rangeSearchDecl = ["set(", "willSet(", "didSet(", "subscript (", "var "]
            let equalSearchDecl = ["init", "init?", "deinit", "get"]
            let isRangeSpecial = rangeSearchDecl.contains{decl.hasPrefix($0)}
            let isEqualSpecial = equalSearchDecl.contains{decl == $0}
            
            var wholeDecl = "\(accessControl.rawValue)\(decoration.map{$0.rawValue}.joined(separator: ""))\((isRangeSpecial || isEqualSpecial) ? "" : "func ")\(decl)\(SimpleDecl.genericDecl(decl: generic))"
            if let parameterDecl = parameter {
                var rearDecl = "(\(parameterDecl))"
                
                if throwing {
                    rearDecl += " throws"
                }
                
                if let returnTypeDecl = returnType {
                    rearDecl += " -> \(returnTypeDecl)"
                }
                
                if let constraintDecl = constraint {
                    rearDecl += " \(SimpleStmt.wh.rawValue) \(constraintDecl)"
                }
                
                wholeDecl += rearDecl
            } else if let returnTypeDecl = returnType {
                var rearDecl = "()\(throwing ? " throws" : "") -> \(returnTypeDecl)"
                
                if let constraintDecl = constraint {
                    rearDecl += " \(SimpleStmt.wh.rawValue) \(constraintDecl)"
                }
                
                wholeDecl += rearDecl
            } else {
                var rearDecl = "()\(throwing ? " throws" : "")"
                
                if let constraintDecl = constraint {
                    rearDecl += " \(SimpleStmt.wh.rawValue) \(constraintDecl)"
                }
                
                wholeDecl += rearDecl
            }
            
            if let body = body {
                return ["\(wholeDecl) \(SimpleStmt.leftBracket.rawValue)",
                    -->body,
                    SimpleStmt.rightBracket.rawValue].joined(separator: "\n")
            } else {
                return wholeDecl
            }
        }
    }

    static func Func(accessControl: AccessControl,
                     decoration: [FuncDecoration],
                     generic: Generic?,
                     constraint: String?,
                     decl: String,
                     parameter: String?,
                     throwing: Bool,
                     returnType: Type?,
                     body: () -> [String]?) -> Funcz {
        return Funcz(accessControl: accessControl,
                     decoration: decoration,
                     generic: generic,
                     constraint: constraint,
                     decl: decl,
                     parameter: parameter,
                     throwing: throwing,
                     returnType: returnType,
                     body: body())
    }
    
    fileprivate static func injectProtocolComponent(funcz: inout [Funcz]?, protocolComponent: [ProtocolComponent]?) {
        if let protocolComponent = protocolComponent {
            var injectingFun = [Funcz]()
            
            protocolComponent.forEach() { (name, member, fun) in
                if let couldInjectFun = fun {
                    injectingFun += couldInjectFun
                }
            }
            
            if funcz != nil {
                funcz! += injectingFun
            }
        }
    }
    
    fileprivate static func injectProtocolComponent(memberVariable: inout [MemberVariable]?, funcz: inout [Funcz]?, protocolComponent: [ProtocolComponent]?) {
        if let protocolComponent = protocolComponent {
            var injectingMem = [MemberVariable]()
            var injectingFun = [Funcz]()
            
            protocolComponent.forEach() { (name, member, fun) in
                if let couldInjectMem = member {
                    injectingMem += couldInjectMem
                }
                if let couldInjectFun = fun {
                    injectingFun += couldInjectFun
                }
            }
            
            if memberVariable != nil {
                memberVariable! += injectingMem
            }
            
            if funcz != nil {
                funcz! += injectingFun
            }
        }
    }
    
    enum Element {
        case none
        case importz(files: [String])
        case globalDecl(globalDecl: [String])
        case function(functions: [Funcz])
        case classz(name: Variable,
            inherited: Variable?,
            accessControl: AccessControl,
            decoration: [ClassDecoration],
            generic: Generic?,
            component: [Element]?,
            protocolComponent: [ProtocolComponent]?,
            typeDecl: [String]?,
            memberVariable: [MemberVariable]?,
            funcz: [Funcz]?)
        case structz(name: String,
            accessControl: AccessControl,
            generic: Generic?,
            component: [Element]?,
            protocolComponent: [ProtocolComponent]?,
            typeDecl: [String]?,
            memberVariable: [MemberVariable]?,
            funcz: [Funcz]?)
        case enumz(name: String,
            accessControl: AccessControl,
            decoration: [EnumDecoration],
            generic: Generic?,
            component: [Element]?,
            protocolComponent: [ProtocolComponent]?,
            typeDecl: [String]?,
            globalVariable: [GlobalVariable]?,
            caseVariable: [CaseVariable]?,
            funcz: [Funcz]?)
        case extensionz(name: String,
            accessControl: AccessControl,
            constraint: String?,
            component: [Element]?,
            protocolComponent: [ProtocolComponent]?,
            typeDecl: [String]?,
            memberVariable: [MemberVariable]?,
            funcz: [Funcz]?)
        case protocolz(name: String,
            accessControl: AccessControl,
            typeDecl: [String]?,
            memberVariable: [MemberVariable]?,
            funcz: [Funcz]?)
    }
    
    struct Class: RepresentComposite {
        let name: Variable
        let inherited: Variable?
        let accessControl: AccessControl
        let decoration: [ClassDecoration]
        let generic: Generic?
        var component: [RepresentComposite]?
        let protocolComponent: [ProtocolComponent]?
        let typeDecl: [String]?
        var memberVariable: [MemberVariable]?
        var funcz: [Funcz]?
        
        init(name: Variable,
             inherited: Variable?,
             accessControl: AccessControl,
             decoration: [ClassDecoration],
             generic: Generic?,
             component: [RepresentComposite]?,
             protocolComponent: [ProtocolComponent]?,
             typeDecl: [String]?,
             memberVariable: [MemberVariable]?,
             funcz: [Funcz]?) {
            self.name = name
            self.inherited = inherited
            self.accessControl = accessControl
            self.decoration = decoration
            self.generic = generic
            self.component = component
            self.protocolComponent = protocolComponent
            self.typeDecl = typeDecl
            self.memberVariable = memberVariable
            self.funcz = funcz
            Swift.injectProtocolComponent(memberVariable: &self.memberVariable, funcz: &self.funcz, protocolComponent: self.protocolComponent)
        }
        
        func represent() -> [String] {
            let componentStmt = component.map{$0.map{$0.represent().joined(separator: "\n")}}
            let memberVariableStmt = memberVariable.map{$0.map{SimpleDecl.memberVariableDecl(decl: $0)}}
            let funcStmt = funcz.map{$0.map{$0.represent()}}
            let stmt = plus(left: plus(left: plus(left: typeDecl, right: componentStmt), right: memberVariableStmt), right:  funcStmt)
            
            return CompoundDecl.classDecl(name: name,
                                          inherited: inherited,
                                          accessControl: accessControl,
                                          decoration: decoration,
                                          generic: generic,
                                          protocolComponent: protocolComponent,
                                          stmt: stmt)
        }
    }
    
    struct Struct: RepresentComposite {
        let name: String
        let accessControl: AccessControl
        let generic: Generic?
        var component: [RepresentComposite]?
        let protocolComponent: [ProtocolComponent]?
        let typeDecl: [String]?
        var memberVariable: [MemberVariable]?
        var funcz: [Funcz]?
        
        init(name: String,
             accessControl: AccessControl,
             generic: Generic?,
             component: [RepresentComposite]?,
             protocolComponent: [ProtocolComponent]?,
             typeDecl: [String]?,
             memberVariable: [MemberVariable]?,
             funcz: [Funcz]?) {
            self.name = name
            self.accessControl = accessControl
            self.generic = generic
            self.component = component
            self.protocolComponent = protocolComponent
            self.typeDecl = typeDecl
            self.memberVariable = memberVariable
            self.funcz = funcz
            Swift.injectProtocolComponent(memberVariable: &self.memberVariable, funcz: &self.funcz, protocolComponent: protocolComponent)
        }
        
        func represent() -> [String] {
            let componentStmt = component.map{$0.map{$0.represent().joined(separator: "\n")}}
            let memberVariableStmt = memberVariable.map{$0.map{SimpleDecl.memberVariableDecl(decl: $0)}}
            let funcStmt = funcz.map{$0.map{$0.represent()}}
            let stmt = plus(left: plus(left: plus(left: typeDecl, right: componentStmt), right: memberVariableStmt), right:  funcStmt)

            return CompoundDecl.structDecl(name: name,
                                           accessControl: accessControl,
                                           generic: generic,
                                           protocolComponent: protocolComponent,
                                           stmt: stmt)
        }
    }
    
    struct Enum: RepresentComposite {
        let name: String
        let accessControl: AccessControl
        let decoration: [EnumDecoration]
        let generic: Generic?
        var component: [RepresentComposite]?
        let protocolComponent: [ProtocolComponent]?
        let typeDecl: [String]?
        let globalVariable: [GlobalVariable]?
        let caseVariable: [CaseVariable]?
        var funcz: [Funcz]?
        
        init(name: String,
             accessControl: AccessControl,
             decoration: [EnumDecoration],
             generic: Generic?,
             component: [RepresentComposite]?,
             protocolComponent: [ProtocolComponent]?,
             typeDecl: [String]?,
             globalVariable: [GlobalVariable]?,
             caseVariable: [CaseVariable]?,
             funcz: [Funcz]?) {
            self.name = name
            self.accessControl = accessControl
            self.decoration = decoration
            self.generic = generic
            self.component = component
            self.protocolComponent = protocolComponent
            self.typeDecl = typeDecl
            self.globalVariable = globalVariable
            self.caseVariable = caseVariable
            self.funcz = funcz
            Swift.injectProtocolComponent(funcz: &self.funcz, protocolComponent: self.protocolComponent)
        }
        
        func represent() -> [String] {
            let componentStmt = component.map{$0.map{$0.represent().joined(separator: "\n")}}
            let caseStmt = caseVariable.map{$0.map{SimpleDecl.caseVariableDecl(decl: $0)}}
            let globalStmt = globalVariable.map{$0.map{SimpleDecl.globalVariableDecl(decl: $0)}}
            let funcStmt = funcz.map{$0.map{$0.represent()}}
            let stmt = plus(left: plus(left: plus(left: plus(left: typeDecl, right: componentStmt), right: globalStmt), right:  caseStmt), right: funcStmt)
            
            return CompoundDecl.enumDecl(name: name,
                                         accessControl: accessControl,
                                         decoration: decoration,
                                         generic: generic,
                                         protocolComponent: protocolComponent,
                                         stmt: stmt)
        }
    }
    
    struct Extension: RepresentComposite {
        let name: String
        let accessControl: AccessControl
        let constraint: String?
        var component: [RepresentComposite]?
        let protocolComponent: [ProtocolComponent]?
        let typeDecl: [String]?
        var memberVariable: [MemberVariable]?
        var funcz: [Funcz]?
        
        init(name: String,
             accessControl: AccessControl,
             constraint: String?,
             component: [RepresentComposite]?,
             protocolComponent: [ProtocolComponent]?,
             typeDecl: [String]?,
             memberVariable: [MemberVariable]?,
             funcz: [Funcz]?) {
            self.name = name
            self.accessControl = accessControl
            self.constraint = constraint
            self.component = component
            self.protocolComponent = protocolComponent
            self.typeDecl = typeDecl
            self.memberVariable = memberVariable
            self.funcz = funcz
            Swift.injectProtocolComponent(memberVariable: &self.memberVariable, funcz: &self.funcz, protocolComponent: protocolComponent)
        }
        
        func represent() -> [String] {
            let componentStmt = component.map{$0.map{$0.represent().joined(separator: "\n")}}
            let memberVariableStmt = memberVariable.map{$0.map{SimpleDecl.memberVariableDecl(decl: $0)}}
            let funcStmt = funcz.map{$0.map{$0.represent()}}
            let stmt = plus(left: plus(left: plus(left: typeDecl, right: componentStmt), right: memberVariableStmt), right:  funcStmt)
            
            return CompoundDecl.extensionDecl(name: name,
                                              accessControl: accessControl,
                                              constraint: constraint,
                                              protocolComponent: protocolComponent,
                                              stmt: stmt)
        }
    }
    
    struct Protocolz {
        let name: String
        let accessControl: AccessControl
        let typeDecl: [String]?
        let memberVariable: [MemberVariable]?
        let funcz: [Funcz]?
        
        func represent() -> [String] {
            let memberVariableStmt = memberVariable.map{$0.map{SimpleDecl.memberVariableDecl(decl: $0)}}
            let funcStmt = funcz.map{$0.map{$0.represent()}}
            let stmt = plus(left: plus(left: typeDecl, right: memberVariableStmt), right:  funcStmt)

            return CompoundDecl.protocolDecl(name: name, accessControl: accessControl, stmt: stmt)
        }
    }
}


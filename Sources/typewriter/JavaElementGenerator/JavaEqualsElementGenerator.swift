//
//  JavaEqualsElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/14.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension JavaModelElementGenerator {
    func generateEqualsMethod(ir: IR) -> Java.Methodz {
        var fieldsStmt = "return \(ir.memberVariableList.map{generateEqualsStmt(memberVariable: $0)}.joined(separator: "\n       && "));"
        if ir.memberVariableList.count <= 0 {
            fieldsStmt = "return true;"
        } else {
            fieldsStmt = ["\(ir.desName) other = (\(ir.desName)) obj;",
                          fieldsStmt].joined(separator: "\n")
        }
        
        return Java.Method(annotations: ["@Override"],
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: "equals",
                           parameter: "Object obj",
                           throwsz: nil,
                           returnType: "boolean",
                           body: {
                            ["if (obj == this) return true;",
                             "if (!(obj instanceof \(ir.desName))) return false;",
                             fieldsStmt]
        })
    }
    
    fileprivate func generateEqualsStmt(memberVariable: MemberVariable) -> String {
        let type = finalType(memberVariable: memberVariable)
        let variable = finalVariable(memberVariable: memberVariable)
        
        switch type {
        case .float:
            return "Float.compare(\(variable), other.\(variable)) == 1"
        case .double:
            return "Double.compare(\(variable), other.\(variable)) == 1"
        case .uint32:
            return "Integer.compare(\(variable), other.\(variable)) == 1"
        case .uint64:
            return "Long.compare(\(variable), other.\(variable)) == 1"
        case .sint32:
            return "Integer.compare(\(variable), other.\(variable)) == 1"
        case .sint64:
            return "Long.compare(\(variable), other.\(variable)) == 1"
        case .bool:
            return "Boolean.compare(\(variable), other.\(variable)) == 1"
        default:
            return "(\(variable) != null ? \(variable).equals(other.\(variable)) : other.\(variable) == null)"
        }
    }
}

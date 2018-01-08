//
//  JavaHashCodeElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/14.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension JavaModelElementGenerator {
    func generateHashCodeMethod(ir: IR) -> Java.Methodz {
        return Java.Method(annotations: ["@Override"],
                           accessControl: .publicz,
                           decoration: [.none],
                           generic: nil,
                           decl: "hashCode",
                           parameter: nil,
                           throwsz: nil,
                           returnType: "int",
                           body: {
                            ["int result = super.hashCode() != 0 ? super.hashCode() : 1;"] +
                            ir.memberVariableList.map(generateHashCodeStmt) +
                            ["return result;"]
        })
    }
    
    fileprivate func generateHashCodeStmt(memberVariable: MemberVariable) -> String {
        let type = finalType(memberVariable: memberVariable)
        let variable = finalVariable(memberVariable: memberVariable)
        
        switch type {
        case .float:
            return "result = result * 37 + Float.valueOf(\(variable)).hashCode();"
        case .double:
            return "result = result * 37 + Double.valueOf(\(variable)).hashCode();"
        case .uint32:
            return "result = result * 37 + Integer.valueOf(\(variable)).hashCode();"
        case .uint64:
            return "result = result * 37 + Long.valueOf(\(variable)).hashCode();"
        case .sint32:
            return "result = result * 37 + Integer.valueOf(\(variable)).hashCode();"
        case .sint64:
            return "result = result * 37 + Long.valueOf(\(variable)).hashCode();"
        case .bool:
            return "result = result * 37 + Boolean.valueOf(\(variable)).hashCode();"
        default:
            return "result = result * 37 + (\(variable) != null ? \(variable).hashCode() : 0);"
        }
    }
}

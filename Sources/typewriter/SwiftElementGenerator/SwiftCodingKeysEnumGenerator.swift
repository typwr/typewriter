//
//  SwiftCodingKeysEnumGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/23.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension SwiftModelElementGenerator {
    func codingKeysEnumName() -> String {
        return "CodingKeys"
    }
    
    func deduceCodingKeysEnum(ir: IR) -> [Swift.Element]? {
        guard ir.isContainRewrittenName() || ir.isContainFlattenMemberVariable() || ir.isContainBuildInRewrittenType() else {
            return nil
        }
        
        let rewrittenNameMap = ir.makeRewrittenNameMap()
        let hierarchy = ir.memberVariableHierarchy()
        return hierarchy.map({ (element) -> Swift.Element in
            var name = element.1
            if name == ir.memberVariableRootPlaceHolder() {
                name = codingKeysEnumName()
            } else {
                name += codingKeysEnumName()
            }
            
            return generateCodingKeysEnum(name: name,
                                          caseVariable: element.2
                                            .map({ (child) -> Swift.CaseVariable in
                                                if let rewritten = rewrittenNameMap[child] {
                                                    return (child, "\"\(rewritten)\"")
                                                }
                                            
                                                return (child, nil)
                                            }))
        })
    }
    
    fileprivate func generateCodingKeysEnum(name: String, caseVariable: [Swift.CaseVariable]) -> Swift.Element {
        return Swift.Element.enumz(name: name,
                                   accessControl: .none,
                                   decoration: [.none],
                                   generic: nil,
                                   component: nil,
                                   protocolComponent: [("String", nil, nil), ("CodingKey", nil, nil)],
                                   typeDecl: nil,
                                   globalVariable: nil,
                                   caseVariable: caseVariable,
                                   funcz: nil)
    }
}

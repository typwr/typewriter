//
//  JavaParserBuilder.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/8.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

fileprivate enum JavaToken: String {
    case classz = "class"
    case extends = "extends"
    case staticz = "static"
    case final = "final"
    case publicz = "public"
    case protected = "protected"
    case privatez = "private"
    case semoColon = ";"
    case annotation = "@"
    case equal = "="
    case leftBracket = "{"
    case rightBracket = "}"
    case leftParentheses = "("
    case rightParentheses = ")"
    case compoundComment = "*"
    case simpleComment = "//"
}

struct JavaParserBuilder: ParserBuilder {
    static func inputFormat() -> DescribeFormat {
        return DescribeFormat.GPPLJava
    }
    
    static func constructLanguage(context: inout ParserContext, input: String) {
        let interpreters: [JavaTokenInterpretable] = [JavaClassInterpreter(), JavaDeclarationEndInterpreter(), JavaFieldInterpreter()]
        
        for interpreter in interpreters {
            if interpreter.interpreter(context: &context, input: input) {
                break
            }
        }
    }
}

fileprivate protocol JavaTokenInterpretable {
    func interpreter(context: inout ParserContext, input: String) -> Bool
}

fileprivate struct JavaClassInterpreter: JavaTokenInterpretable {
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.hasPrefix(JavaToken.simpleComment.rawValue) || input.hasPrefix(JavaToken.compoundComment.rawValue) {
            return false
        }
        
        if input.range(of: JavaToken.classz.rawValue) != nil {
            
            let grammerSeparated = input.components(separatedBy: " ").map{$0.trimmingDoubleEnd()}
            if let classIdx = grammerSeparated.index(where: { $0 == JavaToken.classz.rawValue }), classIdx < grammerSeparated.count - 1 {
                let className = grammerSeparated[classIdx + 1]
                
                if JavaParserBuilder.filterProto(src: className) {
                    if let extendsIdx = grammerSeparated.index(where: { $0 == JavaToken.extends.rawValue }), extendsIdx < grammerSeparated.count - 1 {
                        context.srcInheriting = grammerSeparated[extendsIdx + 1]
                    }
                    
                    context.srcName  = className
                    context.isCollecting = true
                    return true
                }                
            }
        }
        
        return false
    }
}

fileprivate struct JavaFieldInterpreter: JavaTokenInterpretable {
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        guard context.isCollecting else {
            return false
        }
        
        if input.hasPrefix(JavaToken.simpleComment.rawValue) || input.hasPrefix(JavaToken.compoundComment.rawValue) {
            return false
        }
        
        var grammerSeparated = input.components(separatedBy: " ")
            .map{$0.trimmingDoubleEnd()}
            .filter{$0.count > 0}
        
        if input.range(of: "<") != nil && input.range(of: ">") != nil {
            let lhsGenericRange = input.range(of: "<")
            let rhsGenericRange = input.range(of: ">", options: .backwards)
            
            var decoration = String(input[..<lhsGenericRange!.lowerBound]).components(separatedBy: " ")
            let type = decoration.removeLast() + String(input[lhsGenericRange!.lowerBound ..< rhsGenericRange!.upperBound])
            let name = String(input[rhsGenericRange!.upperBound...])
            
            grammerSeparated = decoration + [type, name]
        }

        guard grammerSeparated.contains(where: { (element) -> Bool in
            if element == JavaToken.equal.rawValue ||
                element == JavaToken.staticz.rawValue ||
                element == JavaToken.leftBracket.rawValue ||
                element == JavaToken.rightBracket.rawValue {
                return false
            }
            
            if element.range(of: JavaToken.annotation.rawValue) != nil ||
                element.range(of: JavaToken.leftParentheses.rawValue) != nil ||
                element.range(of: JavaToken.rightParentheses.rawValue) != nil {
                return false
            }
            
            return true
        }) else {
            return false
        }
        
        let preciseMatch = grammerSeparated.filter { (element) -> Bool in
            if element == JavaToken.final.rawValue ||
                element == JavaToken.publicz.rawValue ||
                element == JavaToken.protected.rawValue ||
                element == JavaToken.privatez.rawValue ||
                element == JavaToken.semoColon.rawValue {
                return false
            }
            
            return true
        }
        
        guard preciseMatch.count == 2 else {
            return false
        }
        
        let type = preciseMatch.first!
        let variable = preciseMatch.last!.replacingOccurrences(of: ";", with: "").trimmingDoubleEnd()
        context.memberVariableMap[variable] = (ObjCParserBuilder.queryComment(commentQueue: &context.commentQueue), type, variable, nil, nil, .required, nil)
        context.memberVariableQueue.append(variable)
        
        return true
    }
}

fileprivate struct JavaDeclarationEndInterpreter: JavaTokenInterpretable {
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        guard context.isCollecting else {
            return false
        }
        
        if input.hasPrefix(JavaToken.simpleComment.rawValue) || input.hasPrefix(JavaToken.compoundComment.rawValue) {
            return false
        }
        
        let grammerSeparated = input.components(separatedBy: " ").map{$0.trimmingDoubleEnd()}
        
        if grammerSeparated.count > 0 {
            if grammerSeparated.last! == JavaToken.rightBracket.rawValue {
                context.isCollecting = false
                return true
            } else if grammerSeparated.last! == JavaToken.leftBracket.rawValue {
                if let classIdx = grammerSeparated.index(where: { $0 == JavaToken.classz.rawValue }), classIdx < grammerSeparated.count - 1 {
                    let className = grammerSeparated[classIdx + 1]
                    if className.hasSuffix("Builder") {
                        context.isCollecting = false
                        return true
                    }
                } else {
                    context.isCollecting = false
                    return true
                }
            }
        }
        
        return false
    }
}


//
//  ObjCParserBuilder.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/19.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

fileprivate enum ObjCToken: String {
    case interface = "@interface"
    case property = "@property"
    case end = "@end"
}

struct ObjCParserBuilder: ParserBuilder {
    static func inputFormat() -> DescribeFormat {
        return DescribeFormat.GPPLObjC
    }
    
    static func constructLanguage(context: inout ParserContext, input: String) {
        let interpreters: [ObjCTokenInterpretable] = [ObjCInterfaceInterpreter(), ObjCEndInterpreter(), ObjCPropertyInterpreter()]
        
        for interpreter in interpreters {
            if interpreter.interpreter(context: &context, input: input) {
                break
            }
        }
    }
}

fileprivate protocol ObjCTokenInterpretable {
    var token: ObjCToken { get }
    func interpreter(context: inout ParserContext, input: String) -> Bool
}

fileprivate struct ObjCInterfaceInterpreter: ObjCTokenInterpretable {
    fileprivate var token: ObjCToken {
        get {
            return ObjCToken.interface
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        if input.hasPrefix(token.rawValue) {
            let interfacePrefixBounds = input.range(of: token.rawValue)
            let interfacePrefixFree = String(input[interfacePrefixBounds!.upperBound...])
            let whitespaceFree = interfacePrefixFree.replacingOccurrences(of: " ", with: "")
            let interfaceDecl = whitespaceFree.components(separatedBy: ":")
            var interfaceName: Variable?
            var inheritedName: Variable?
            if interfaceDecl.count == 2 {
                interfaceName = interfaceDecl[0]
                inheritedName = interfaceDecl[1]
            }
            
            if let interfaceName = interfaceName, ObjCParserBuilder.filterProto(src: interfaceName)  {
                context.srcName = interfaceName
                context.srcInheriting = inheritedName
                
                context.isCollecting = true
                return true
            }
        }
        
        return false
    }
}

fileprivate struct ObjCPropertyInterpreter: ObjCTokenInterpretable {
    fileprivate var token: ObjCToken {
        get {
            return ObjCToken.property
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        guard context.isCollecting else {
            return false
        }
        
        if input.hasPrefix(token.rawValue) {
            if let rightParenthesesBounds = input.range(of: ")") {
                var nullable = Nullable.required
                let propertyStr = String(input[..<rightParenthesesBounds.lowerBound])
                if propertyStr.range(of: "nullable") != nil {
                    nullable = Nullable.optional
                }
                let propertySyntaxFree = String(input[rightParenthesesBounds.upperBound...])
                let leftWhitespaceFree = propertySyntaxFree.trimmingLeftEndWhitespaces()
                var type: Type
                var variable: Variable
                if let referenceBounds = leftWhitespaceFree.range(of: "*", options: .backwards) {
                    let referenceFree = leftWhitespaceFree.replacingCharacters(in: referenceBounds, with: "")
                    var separatedArr = referenceFree.components(separatedBy: " ").filter({ (compoent) -> Bool in
                        return !compoent.isEmpty && compoent != ";"
                    })
                    variable = separatedArr.removeLast().replacingOccurrences(of: ";", with: "")
                    type = separatedArr.joined(separator: " ") + " *"
                } else {
                    var separatedArr = leftWhitespaceFree.components(separatedBy: " ").filter({ (compoent) -> Bool in
                        return !compoent.isEmpty && compoent != ";"
                    })
                    
                    if separatedArr.count < 2 {
                        print("Error: tokenize encounter bad syntax")
                        exit(1)
                    } else if separatedArr.count == 2 {
                        type = separatedArr.first!
                        variable = separatedArr.last!.replacingOccurrences(of: ";", with: "")
                    } else {
                        variable = separatedArr.removeLast().replacingOccurrences(of: ";", with: "")
                        type = separatedArr.joined(separator: " ")
                    }
                }
                
                context.memberVariableMap[variable] = (ObjCParserBuilder.queryComment(commentQueue: &context.commentQueue), type, variable, nil, nil, nullable, nil)
                context.memberVariableQueue.append(variable)
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct ObjCEndInterpreter: ObjCTokenInterpretable {
    fileprivate var token: ObjCToken {
        get {
            return ObjCToken.end
        }
    }
    
    fileprivate func interpreter(context: inout ParserContext, input: String) -> Bool {
        guard context.isCollecting else {
            return false
        }
        
        if input.hasPrefix(token.rawValue) {
            context.isCollecting = false
            return true
        }
        
        return false
    }
}

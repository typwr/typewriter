//
//  JsonParser.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/25.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

fileprivate enum KeyToken: String {
    case generate = "generate"
    case inherit = "inherit"
    case implement = "implement"
    case options = "options"
    case memberVariable = "memberVariable"
}

fileprivate enum MemberVariableKeyToken: String {
    case type = "type"
    case nullable = "nullable"
    case rewrittenType = "rewrittenType"
    case rewrittenName = "rewrittenName"
    case flatten = "flatten"
    case annotation = "annotation"
}

fileprivate enum OptionToken: String {
    case constructOnly = "constructOnly"
    case immutable = "immutable"
    case initializerPreprocess = "initializerPreprocess"
    case unidirectionDataflow = "unidirectionDataflow"
    
    func toAnalysisOptionType() -> AnalysisOptionType {
        switch self {
        case .constructOnly:
            return AnalysisOptionType.constructOnly
        case .immutable:
            return AnalysisOptionType.immutable
        case .initializerPreprocess:
            return AnalysisOptionType.initializerPreprocess
        case .unidirectionDataflow:
            return AnalysisOptionType.unidirectionDataflow
        }
    }
    
    static func transformToAnalysisOptions(optionTokens: [OptionToken]) -> AnalysisOptions {
        var res = AnalysisOptions()
        optionTokens.forEach { (token) in
            let analysisOption = token.toAnalysisOptionType()
            res[analysisOption] = analysisOption.rawValue
        }
        return res
    }
}

protocol JsonParser {
    static func parse(file: (String, [String])) -> IR
    static func serialize(file: [String]) -> Any
    static func tokenize(path: String, json: Any) -> IR
}

extension JsonParser {
    static func parse(file: (String, [String])) -> IR {
        return tokenize(path: file.0, json: serialize(file: file.1))
    }
    
    static func serialize(file: [String]) -> Any {
        guard let data = file.joined(separator: "\n").data(using: String.Encoding.utf8) else {
            print("Error: read data from file")
            exit(1)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
            print("Error: json serialization from file")
            exit(1)
        }
        
        return json
    }
}

struct DictionaryParser: JsonParser {
    static func tokenize(path: String, json: Any) -> IR {
        guard let dic = json as? Dictionary<String, Any> else {
            print("Error: json represnt from file is not a dictionary")
            exit(1)
        }
        
        var context = JsonParserContext()
        let interpreters: [KeyInterpretable] = [GenerateInterpreter(),
                                                InheritInterpreter(),
                                                ImplementInterpreter(),
                                                OptionsInterpreter(),
                                                MemberVariableInterpreter()]
        for elements in dic {
            for interpreter in interpreters {
                if interpreter.interpreter(context: &context, input: elements) {
                    break
                }
            }
        }
        
        return IR.translationToIR(path: path,
                                  inputFormat: .JSON,
                                  srcName: context.generateName,
                                  srcInheriting: nil,
                                  srcImplement: context.implement,
                                  desName: context.generateName,
                                  desInheriting: context.inherit,
                                  memberVariableToken: context.memberVariableToken,
                                  options: OptionToken.transformToAnalysisOptions(optionTokens: context.options),
                                  flattenToken: context.flattenToken)
    }
}

fileprivate struct JsonParserContext {
    var generateName: String
    var inherit: String?
    var implement: [String]?
    var options: [OptionToken]
    var memberVariableToken: [MemberVariableToken]
    var flattenToken: [FlattenToken]?
    
    init() {
        generateName = String()
        options = [OptionToken]()
        memberVariableToken = [MemberVariableToken]()
    }
}

fileprivate protocol KeyInterpretable {
    var keyToken: KeyToken { get }
    func interpreter(context: inout JsonParserContext, input: (String, Any)) -> Bool
}

fileprivate struct GenerateInterpreter: KeyInterpretable {
    fileprivate var keyToken: KeyToken {
        get {
            return KeyToken.generate
        }
    }
    
    fileprivate func interpreter(context: inout JsonParserContext, input: (String, Any)) -> Bool {
        if input.0 == keyToken.rawValue {
            if let expansion = input.1 as? String {
                context.generateName = expansion
            }
            
            return true
        }

        return false
    }
}

fileprivate struct InheritInterpreter: KeyInterpretable {
    fileprivate var keyToken: KeyToken {
        get {
            return KeyToken.inherit
        }
    }
    
    fileprivate func interpreter(context: inout JsonParserContext, input: (String, Any)) -> Bool {
        if input.0 == keyToken.rawValue {
            if let expansion = input.1 as? String {
                context.inherit = expansion
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct ImplementInterpreter: KeyInterpretable {
    fileprivate var keyToken: KeyToken {
        get {
            return KeyToken.implement
        }
    }
    
    fileprivate func interpreter(context: inout JsonParserContext, input: (String, Any)) -> Bool {
        if input.0 == keyToken.rawValue {
            if let expansion = input.1 as? [String] {
                context.implement = expansion
            }
            
            return true
        }
        
        return false
    }
}

fileprivate struct OptionsInterpreter: KeyInterpretable {
    fileprivate var keyToken: KeyToken {
        get {
            return KeyToken.options
        }
    }
    
    fileprivate func interpreter(context: inout JsonParserContext, input: (String, Any)) -> Bool {
        if input.0 == keyToken.rawValue {
            if let expansion = input.1 as? Array<String> {
                expansion.forEach({ (token) in
                    switch token {
                    case OptionToken.constructOnly.rawValue:
                        context.options.append(OptionToken.constructOnly)
                    case OptionToken.immutable.rawValue:
                        context.options.append(OptionToken.immutable)
                    case OptionToken.initializerPreprocess.rawValue:
                        context.options.append(OptionToken.initializerPreprocess)
                    case OptionToken.unidirectionDataflow.rawValue:
                        context.options.append(OptionToken.unidirectionDataflow)
                    default:
                        break
                    }
                })
                
                return true
            }
        }

        return false
    }
}

fileprivate struct MemberVariableInterpreter: KeyInterpretable {
    fileprivate var keyToken: KeyToken {
        get {
            return KeyToken.memberVariable
        }
    }
    
    fileprivate func interpreter(context: inout JsonParserContext, input: (String, Any)) -> Bool {
        if input.0 == keyToken.rawValue {
            if let expansion = input.1 as? Dictionary<String, Dictionary<String, String>> {
                for elements in expansion {
                    var type = ""
                    let variable = elements.key
                    var finalNullable = Nullable.required
                    var rewrittenVariable: Variable?
                    var rewrittenType: Type?
                    var nestedPath: String?
                    var annotation: Annotation?
                    
                    for element in elements.value {
                        switch element.key {
                        case MemberVariableKeyToken.type.rawValue:
                            type = element.value
                        case MemberVariableKeyToken.nullable.rawValue:
                            switch element.value {
                            case Nullable.required.rawValue:
                                finalNullable = Nullable.required
                            case Nullable.almost.rawValue:
                                finalNullable = Nullable.almost
                            case Nullable.optional.rawValue:
                                finalNullable = Nullable.optional
                            default:
                                break
                            }
                        case MemberVariableKeyToken.rewrittenType.rawValue:
                            rewrittenType = element.value
                        case MemberVariableKeyToken.rewrittenName.rawValue:
                            rewrittenVariable = element.value
                        case MemberVariableKeyToken.flatten.rawValue:
                            nestedPath = element.value
                        case MemberVariableKeyToken.annotation.rawValue:
                            annotation = element.value.components(separatedBy: "&&").map{$0.trimmingDoubleEnd()}
                        default:
                            break
                        }
                    }
                    
                    if type.isEmpty || variable.isEmpty {
                        continue
                    }
                    
                    context.memberVariableToken.append((nil, type, variable, rewrittenType, rewrittenVariable, finalNullable, annotation))
                    
                    if let nestedPath = nestedPath {
                        if context.flattenToken != nil {
                            context.flattenToken?.append((variable, nestedPath))
                        } else {
                            context.flattenToken = Array()
                            context.flattenToken?.append((variable, nestedPath))
                        }
                    }
                }
            }
            
            return true
        }
        
        return false
    }
}

//
//  JavaTypeConvertor.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/7.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

func JavaTypeToIRType(type: Type) -> IRType {
    let preprocessType = type.trimmingDoubleEnd()
    if preprocessType.hasSuffix("]") {
        let elemetTypeRange = preprocessType.range(of: "[")
        if elemetTypeRange == nil {
            return IRType.ambiguous(type: preprocessType)
        } else {
            let elementType = String(preprocessType[..<elemetTypeRange!.lowerBound])
            return IRType.array(type: JavaTypeToIRType(type: elementType))
        }
    }
    
    if preprocessType.hasPrefix("List") {
        let lElemetTypeRange = preprocessType.range(of: "<")
        let rElementTypeRange = preprocessType.range(of: ">", options: .backwards)
        if lElemetTypeRange == nil || rElementTypeRange == nil {
            return IRType.array(type: nil)
        } else {
            let elementType = String(preprocessType[lElemetTypeRange!.upperBound ..< rElementTypeRange!.lowerBound])
            return IRType.array(type: JavaTypeToIRType(type: elementType))
        }
    }
    
    if preprocessType.hasPrefix("Map") {
        let keyTypeRange = preprocessType.range(of: "<")
        let seperatorRange = preprocessType.range(of: ",")
        let valueTypeRange = preprocessType.range(of: ">", options: .backwards)
        if keyTypeRange == nil || seperatorRange == nil || valueTypeRange == nil {
            return IRType.map(keyType: nil, valueType: nil)
        } else {
            let keyType = String(preprocessType[keyTypeRange!.upperBound ..< seperatorRange!.lowerBound])
            let valueType = String(preprocessType[seperatorRange!.upperBound ..< valueTypeRange!.lowerBound])
            return IRType.map(keyType: JavaTypeToIRType(type: keyType), valueType: JavaTypeToIRType(type: valueType))
        }
    }
    
    switch preprocessType {
    case "float", "Float":
        return IRType.float
    case "double", "Double":
        return IRType.double
    case "int", "Integer":
        return IRType.uint32
    case "long", "Long":
        return IRType.uint64
    case "int", "Integer":
        return IRType.sint32
    case "long", "Long":
        return IRType.sint64
    case "Boolean", "boolean":
        return IRType.bool
    case "String":
        return IRType.string
    case "Date":
        return IRType.date
    case "Object", "?":
        return IRType.any
    default:
        return IRType.ambiguous(type: preprocessType)
    }
}

func IRTypeToJavaType(type: IRType) -> Type {
    switch type {
    case .float:
        return "float"
    case .double:
        return "double"
    case .uint32:
        return "int"
    case .uint64:
        return "long"
    case .sint32:
        return "int"
    case .sint64:
        return "long"
    case .bool:
        return "boolean"
    case .string:
        return "String"
    case .date:
        return "Date"
    case .array(let type):
        return (type == nil) ? "List" : "List<" + IRTypeToJavaType(type: type!) + ">"
    case .map(let keyType, let valueType):
        return (keyType == nil || valueType == nil) ? "Map" : "Map<" + IRTypeToJavaType(type: keyType!) + ", " + IRTypeToJavaType(type: valueType!) + ">"
    case .ambiguous(let type):
        return type
    case .any:
        return "Object"
    }
}

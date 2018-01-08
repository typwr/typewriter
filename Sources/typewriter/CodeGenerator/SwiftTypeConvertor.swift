//
//  SwiftTypeConvertor.swift
//  typewriter
//
//  Created by mrriddler on 2017/9/3.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

func SwiftTypeToIRType(type: Type) -> IRType {
    let preprocessType = type.trimmingDoubleEnd()
    if preprocessType.hasPrefix("[") && preprocessType.hasSuffix("]") {
        let beginTokenRange = preprocessType.range(of: "[")
        let endTokenRange = preprocessType.range(of: "]", options: .backwards)
        let separator = String(preprocessType[beginTokenRange!.upperBound ..< endTokenRange!.lowerBound]).findSeparatorRangeInNestedGrammer(beginToken: "[", endToken: "]", separator: ":")
        
        if let separatorRange = separator {
            let keyType = String(preprocessType[ beginTokenRange!.upperBound ..< separatorRange.lowerBound]).trimmingDoubleEnd()
            let valueType = String(preprocessType[ separatorRange.upperBound ..< endTokenRange!.lowerBound]).trimmingDoubleEnd()
            if keyType.isEmpty || valueType.isEmpty {
                return IRType.map(keyType: nil, valueType: nil)
            } else {
                return IRType.map(keyType: SwiftTypeToIRType(type: keyType), valueType: SwiftTypeToIRType(type: valueType))
            }
        } else {
            let elementType = String(preprocessType[beginTokenRange!.upperBound ..< endTokenRange!.lowerBound]).trimmingDoubleEnd()
            if elementType.isEmpty {
                return IRType.array(type: nil)
            } else {
                return IRType.array(type: SwiftTypeToIRType(type: elementType))
            }
        }
    }
    
    switch preprocessType {
    case "CFloat", "Float", "Float32":
        return IRType.float
    case "CDouble", "Double", "Float64":
        return IRType.double
    case "CUnsignedInt", "UInt32":
        return IRType.uint32
    case "CUnsignedLongLong", "UInt64":
        return IRType.uint64
    case "CInt", "Int32":
        return IRType.sint32
    case "CLongLong", "Int64":
        return IRType.sint64
    case "CBool", "Bool":
        return IRType.bool
    case "String":
        return IRType.string
    case "Date":
        return IRType.date
    case "Any":
        return IRType.any
    default:
        return IRType.ambiguous(type: preprocessType)
    }
}

func IRTypeToSwiftType(type: IRType) -> Type {
    switch type {
    case .float:
        return "Float"
    case .double:
        return "Double"
    case .uint32:
        return "UInt32"
    case .uint64:
        return "UInt64"
    case .sint32:
        return "Int32"
    case .sint64:
        return "Int64"
    case .bool:
        return "Bool"
    case .string:
        return "String"
    case .date:
        return "Date"
    case .array(let type):
        return (type == nil) ? "[]" : "[" + IRTypeToSwiftType(type: type!) + "]"
    case .map(let keyType, let valueType):
        return (keyType == nil || valueType == nil) ? "[]" : "[" + IRTypeToSwiftType(type: keyType!) + ": " + IRTypeToSwiftType(type: valueType!) + "]"
    case .ambiguous(let type):
        return type
    case .any:
        return "Any"
    }
}

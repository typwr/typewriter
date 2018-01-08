//
//  IRTypeConverter.swift
//  typewriter
//
//  Created by mrriddler on 2017/7/28.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

func TypeToIRType(type: Type) -> IRType {
    let preprocessType = type.trimmingDoubleEnd()
    if preprocessType.hasPrefix("Array") {
        let lElemetTypeRange = preprocessType.range(of: "<")
        let rElementTypeRange = preprocessType.range(of: ">", options: .backwards)
        if lElemetTypeRange == nil || rElementTypeRange == nil {
            return IRType.array(type: nil)
        } else {
            let elementType = String(preprocessType[lElemetTypeRange!.upperBound ..< rElementTypeRange!.lowerBound])
            return IRType.array(type: TypeToIRType(type: elementType))
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
            return IRType.map(keyType: TypeToIRType(type: keyType), valueType: TypeToIRType(type: valueType))
        }
    }
    
    switch preprocessType {
    case "Float":
        return .float
    case "Double":
        return .double
    case "UInt32":
        return .uint32
    case "UInt64":
        return .uint64
    case "SInt32":
        return .sint32
    case "SInt64":
        return .sint64
    case "Bool":
        return .bool
    case "String":
        return .string
    case "Date":
        return .date
    case "Any":
        return .any
    default:
        return .ambiguous(type: preprocessType)
    }
}

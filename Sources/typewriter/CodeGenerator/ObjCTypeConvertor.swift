//
//  ObjCTypeConvertor.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/6.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

func ObjCTypeToIRType(type: Type) -> IRType {
    let preprocessType = type.trimmingDoubleEnd()
    if preprocessType.hasPrefix("NSArray") || preprocessType.hasPrefix("NSMutableArray") {
        let lElemetTypeRange = preprocessType.range(of: "<")
        let rElementTypeRange = preprocessType.range(of: ">", options: .backwards)
        if lElemetTypeRange == nil || rElementTypeRange == nil {
            return IRType.array(type: nil)
        } else {
            let elementType = String(preprocessType[lElemetTypeRange!.upperBound ..< rElementTypeRange!.lowerBound])
            return IRType.array(type: ObjCTypeToIRType(type: elementType))
        }
    }
    
    if preprocessType.hasPrefix("NSDictionary") || preprocessType.hasPrefix("NSMutableDictionary") {
        let keyTypeRange = preprocessType.range(of: "<")
        let seperatorRange = preprocessType.range(of: ",")
        let valueTypeRange = preprocessType.range(of: ">", options: .backwards)
        if keyTypeRange == nil || seperatorRange == nil || valueTypeRange == nil {
            return IRType.map(keyType: nil, valueType: nil)
        } else {
            let keyType = String(preprocessType[keyTypeRange!.upperBound ..< seperatorRange!.lowerBound])
            let valueType = String(preprocessType[seperatorRange!.upperBound ..< valueTypeRange!.lowerBound])
            return IRType.map(keyType: ObjCTypeToIRType(type: keyType), valueType: ObjCTypeToIRType(type: valueType))
        }
    }
    
    switch preprocessType {
    case "float", "Float32":
        return IRType.float
    case "double", "Float64", "CGFloat":
        return IRType.double
    case "unsigned int", "uint32_t", "UInt32":
         return IRType.uint32
    case "unsigned long long", "uint64_t", "UInt64":
         return IRType.uint64
    case "int", "int32_t", "SInt32":
        return IRType.sint32
    case "long long", "int64_t", "SInt64":
        return IRType.sint64
    case "BOOL":
        return IRType.bool
    case "NSString *", "NSString*":
        return IRType.string
    case "NSDate *", "NSDate*":
        return IRType.date
    case "id":
        return IRType.any
    default:
        return IRType.ambiguous(type: preprocessType)
    }
}

func IRTypeToObjCType(type: IRType) -> Type {
    switch type {
    case .float:
        return "Float32"
    case .double:
        return "Float64"
    case .uint32:
        return "UInt32"
    case .uint64:
        return "UInt64"
    case .sint32:
        return "SInt32"
    case .sint64:
        return "SInt64"
    case .bool:
        return "BOOL"
    case .string:
        return "NSString *"
    case .date:
        return "NSDate *"
    case .array(let type):
        return (type == nil) ? "NSArray *" : "NSArray<" + IRTypeToObjCType(type: type!) + "> *"
    case .map(let keyType, let valueType):
        return (keyType == nil || valueType == nil) ? "NSDictionary *" : "NSDictionary<" + IRTypeToObjCType(type: keyType!) + ", " + IRTypeToObjCType(type: valueType!) + "> *"
    case .ambiguous(let type):
        return type
    case .any:
        return "id"
    }
}

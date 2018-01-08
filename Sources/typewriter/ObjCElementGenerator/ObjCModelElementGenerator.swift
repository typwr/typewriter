//
//  ObjCModelElementGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/14.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct ObjCModelElementGenerator: TwoPhaseDeduceable {
    let ir: IR
    
    init(ir: IR) {
        self.ir = ir
        self.ir.memberVariableList = ObjCModelElementGenerator.deduceMemberVariableList(memberVariableList: self.ir.memberVariableList)
        self.ir.generateModules = ObjCModelElementGenerator.deduceGenerateModules(generateModules: self.ir.generateModules)
    }
    
    static func deduceMemberVariableList(memberVariableList: [MemberVariable]) -> [MemberVariable] {
        return memberVariableList.map { (memberVariable) -> MemberVariable in
            if let rewrittenFormat = memberVariable.3?.2 {
                switch rewrittenFormat {
                case .prototype:
                    if let rewrittenType = memberVariable.3?.0 {
                        if let nestedRewrittenType = rewrittenType.getNestedType(), let nestedOriginal = memberVariable.1.getNestedType() {
                            return (memberVariable.0,
                                    memberVariable.1.setNestedType(desType: nestedOriginal + " *"),
                                    memberVariable.2,
                                    (rewrittenType.setNestedType(desType: nestedRewrittenType + " *"), memberVariable.3?.1, memberVariable.3?.2),
                                    memberVariable.4,
                                    memberVariable.5)
                        }
                    }
                case .json:
                    if let rewrittenType = memberVariable.3?.0 {
                        if let nestedRewrittenType = rewrittenType.getNestedType() {
                            return (memberVariable.0,
                                    memberVariable.1,
                                    memberVariable.2,
                                    (rewrittenType.setNestedType(desType: nestedRewrittenType + " *"), memberVariable.3?.1, memberVariable.3?.2),
                                    memberVariable.4,
                                    memberVariable.5)
                        }
                    }
                }
            }
            return memberVariable
        }
    }
    
    static func deduceGenerateModules(generateModules: GenerateModules) -> GenerateModules {
        return generateModules.filter({ (type) -> Bool in
            switch type {
            case .archive, .copy, .print, .equality, .hash:
                return false
            default:
                return true
            }
        })
    }
    
    fileprivate func findAllPrototype(memberVariableList: [MemberVariable]) -> [String] {
        return ir.findType(find: { (originalType, rewrittenType) -> Type? in
            if let nestedType = originalType.getNestedType() {
                if ObjC.isReferenceType(type: nestedType) {
                    return nestedType
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }).map{$0.formatClassName()}
    }
    
    fileprivate func findAllModel(memberVariableList: [MemberVariable]) -> [String] {
        return ir.findType(find: { (originalType, rewrittenType) -> Type? in
            if let nestedType = rewrittenType.getNestedType() {
                if ObjC.isReferenceType(type: nestedType) {
                    return nestedType
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }).map{$0.formatClassName()}
    }
    
    fileprivate func propertyMemoryAssignmentFor(IRType: IRType) -> ObjC.MemoryAssignment {
        switch IRType {
        case .float, .double, .uint32, .uint64, .sint32, .sint64, .bool:
            return ObjC.MemoryAssignment.assign
        case .string:
            return ObjC.MemoryAssignment.copy
        case .array, .map, .date, .any:
            return ObjC.MemoryAssignment.strong
        case .ambiguous(let type):
            if ObjC.isReferenceType(type: type) {
                return ObjC.MemoryAssignment.strong
            } else {
                return ObjC.MemoryAssignment.assign
            }
        }
    }
    
    fileprivate func propertyNullablezFor(IRType: IRType, required: Bool) -> ObjC.Nullablez {
        switch IRType {
        case .float, .double, .uint32, .uint64, .sint32, .sint64, .bool:
            return ObjC.Nullablez.nonnull
        case .string, .array, .map, .date, .any:
            if required {
                return ObjC.Nullablez.nonnull
            } else {
                return ObjC.Nullablez.nullable
            }
        case .ambiguous(let type):
            if !ObjC.isReferenceType(type: type) {
                return ObjC.Nullablez.nonnull
            } else if required {
                return ObjC.Nullablez.nonnull
            } else {
                return ObjC.Nullablez.nullable
            }
        }
    }
    
    func generateProperty(ir: IR, immutability: ObjC.Immutability) -> [ObjC.Property] {
        let convertor = irTypeConvertor(forLanguage: .ObjC)
        return ir.memberVariableList.map{(memberVariable: MemberVariable) -> ObjC.Property in
            let type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)
            if variable == ir.modelId() {
                return (memberVariable.0,
                        ObjC.Immutability.mutable,
                        propertyMemoryAssignmentFor(IRType: type),
                        propertyNullablezFor(IRType: type, required: memberVariable.4 == .required),
                        convertor(type),
                        variable)
            } else {
                return (memberVariable.0,
                        immutability,
                        propertyMemoryAssignmentFor(IRType: type),
                        propertyNullablezFor(IRType: type, required: memberVariable.4 == .required),
                        convertor(type),
                        variable)
            }
        }
    }
    
    func generateSetterMehods(ir: IR) -> [ObjC.Methodz] {
        let convertor = irTypeConvertor(forLanguage: .ObjC)

        return ir.memberVariableList.flatMap{(memberVariable: MemberVariable) -> ObjC.Methodz? in
            let type = finalType(memberVariable: memberVariable)
            let variable = finalVariable(memberVariable: memberVariable)

            guard variable != ir.modelId() else {
                return nil
            }
            
            return ObjC.Method(decl: "- (void)set\(variable.capitalizingFirstLetter()):(\(convertor(type)))\(variable)", impl: {
                ["_\(variable) = \(variable);"]
            })
        }
    }
    
    func generateElements() -> [ObjC.Element] {
        var modelMethods: [(ObjC.MethodVisibility, ObjC.Methodz)] = []
        var extensionMethods: [(ObjC.MethodVisibility, ObjC.Methodz)] = []
        let srcImplement = ir.srcImplement.map { implements -> [ObjC.Protocolz] in
            return implements.map({ (implement) -> ObjC.Protocolz in
                return (implement, [])
            })
        }
        
        for module in ir.generateModules {
            switch module {
            case .prototypeInitializer:
                if let deduceModelInitMethod = deduceModelInitMethod(ir: ir) {
                    modelMethods.append((.privateMethod, deduceModelInitMethod))
                }
                modelMethods.append((.publicMethod, generateModelClassFromPrototypeInitializer(ir: ir)))
                modelMethods.append((.publicMethod, generateModelFromPrototypeInitializer(ir: ir)))
                if let transformModelFromPrototypeMethod = deduceTransformModelFromPrototypeMethod(ir: ir) {
                    modelMethods.append((.privateMethod, transformModelFromPrototypeMethod))
                }
            case .jsonInitializer:
                modelMethods.append((.publicMethod, generateModelClassFromJSONInitalizer(ir: ir)))
                modelMethods.append((.publicMethod, generateModelFromJSONInitalizer(ir: ir)))
                if let customPropertyMapperMethod = deduceCustomPropertyMapperMethod(ir: ir) {
                    modelMethods.append((.privateMethod, customPropertyMapperMethod))
                }
                if let arrayGenericMapperMethod = deduceArrayGenericClassMapperMethod(ir: ir) {
                    modelMethods.append((.privateMethod, arrayGenericMapperMethod))
                }
                if let dictionaryGenericMapperMethod = deduceDictionaryGenericClassMapperMethod(ir: ir) {
                    modelMethods.append((.privateMethod, dictionaryGenericMapperMethod))
                }
            case .prototypeInitializerPreprocess:
                extensionMethods.append((.publicMethod, generatePrototypeInitializerPreprocessMethod(ir: ir)))
            case .jsonInitializerPreprocess:
                extensionMethods.append((.publicMethod, generateJSONInitializerPreprocessMethod()))
            case .mutableVersion:
                modelMethods.append((.publicMethod, generateModelBuilderInitializerMethod(ir: ir)))
                modelMethods.append((.publicMethod, generateMergeBlockMethod(ir: ir)))
            case .unidirectionalDataflow:
                extensionMethods.append((.publicMethod, generateUnidirectionalDataflowMethod(ir: ir)))
            default:
                break
            }
        }
        
        if ir.isMemberVariableReadOnly() && ir.inputFormat == .JSON {
            modelMethods.append(contentsOf: generateSetterMehods(ir: ir).map{(.privateMethod, $0)})
        }
        
        return [ObjC.Element.importz(files: generateImport(ir: ir)),
                ObjC.Element.classHint(classHint: generateClassHint(ir: ir)),
                ObjC.Element.macro(macro: ["NS_ASSUME_NONNULL_BEGIN"]),
                ObjC.Element.classz(name: ir.desName,
                                    inherited: ir.desInheriting,
                                    protocols: srcImplement,
                                    properties: generateProperty(ir: ir,
                                                                 immutability: ir.isMemberVariableReadOnly() ? ObjC.Immutability.immutable : ObjC.Immutability.mutable),
                                    methods: modelMethods),
                (ir.containModule(type: .mutableVersion) ?
                    generateBuilderClass(ir: ir)
                    : ObjC.Element.none),
                (ir.isGenerateExtension() ?
                    ObjC.Element.category(className: ir.desName,
                                          categoryName: "Extension",
                                          properties: nil,
                                          methods: extensionMethods)
                    : ObjC.Element.none),
                ObjC.Element.macro(macro: ["NS_ASSUME_NONNULL_END"])]
            .filter{(element : ObjC.Element) -> Bool in
                switch element {
                case .none:
                    return false
                default:
                    return true
                }
            }
    }
}

extension ObjCModelElementGenerator {
    private func importSuffix(ir: IR, src: String, special: Bool) -> String {
        if let specialSuffix = ir.specialIncludeSuffix(), special {
            return "\"\(src.formatClassName())\(specialSuffix)\""
        } else {
            return "\"\(src.formatClassName()).h\""
        }
    }
    
    fileprivate func generateClassHint(ir: IR) -> [String] {
        let hintList = (ir.inputFormat == .GPPLObjC ? ["\(ir.srcName)"] : []) +
            (ir.containModule(type: .mutableVersion) ? [builderClassName()] : []) +
            findAllModel(memberVariableList: ir.memberVariableList)
        
        return hintList.removeDuplicate()
    }
    
    fileprivate func generateImport(ir: IR) -> [String] {
        let generalImportList = (["\(ir.desInheriting ?? "<Foundation/Foundation.h>")", "\(ir.desName)"] +
            findAllModel(memberVariableList: ir.memberVariableList))
            .map{importSuffix(ir: ir, src: $0, special: false)}
        let specialImportList = (["\(ir.srcName)"] +
            findAllPrototype(memberVariableList: ir.memberVariableList))
            .map{importSuffix(ir: ir, src: $0, special: true)}
        return (generalImportList + specialImportList).removeDuplicate()
    }
}


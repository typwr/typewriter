//
//  Entry.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/6.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

public let FrameworkVersion = "1.0.0"

public enum DescribeFormat: String {
    case GPPLObjC = "GPPLObjC"
    case GPPLJava = "GPPLJava"
    case JSON = "JSON"
}

public enum Language: String {
    case ObjC = "ObjC"
    case Swift = "Swift"
    case Java = "Java"
}

public enum TranslationOption: String {
    case recursive = "recursive"
}

public typealias TranslationOptions = [TranslationOption: String]
public typealias TranslationOutput = [Language: URL]

func describeFormat(forURL url: URL) -> DescribeFormat {
    if url.lastPathComponent.range(of: ".h") != nil {
        return DescribeFormat.GPPLObjC
    }
    
    if url.lastPathComponent.range(of: ".java") != nil {
        return DescribeFormat.GPPLJava
    }
    
    if url.lastPathComponent.range(of: ".json") != nil {
        return DescribeFormat.JSON
    }

    return DescribeFormat.JSON
}

func tokenizeBuilder(forFormat format: DescribeFormat) -> ((String, [String])) -> IR {
    switch format {
    case .GPPLObjC:
        return ObjCParserBuilder.build
    case .GPPLJava:
        return JavaParserBuilder.build
    case .JSON:
        return DictionaryParser.parse
    }
}

func codeGenerator(forLanguage language: Language) -> (IR) -> [FileRepresent] {
    switch language {
    case .ObjC:
        return ObjCCodeGenerator.generate
    case .Swift:
        return SwiftCodeGenerator.generate
    case .Java:
        return JavaCodeGenerator.generate
    }
}

func typeConvertor(forLanguage language: Language) -> (Type) -> IRType {
    switch language {
    case .ObjC:
        return ObjCTypeToIRType
    case .Swift:
        return SwiftTypeToIRType
    case .Java:
        return JavaTypeToIRType
    }
}

func irTypeConvertor(forLanguage language: Language) -> (IRType) -> Type {
    switch language {
    case .ObjC:
        return IRTypeToObjCType
    case .Swift:
        return IRTypeToSwiftType
    case .Java:
        return IRTypeToJavaType
    }
}

func executeFrontEndParse(src: String, reference: String?) -> IR {
    var referenceURL: URL?
    var relativePath = ""
    
    if let reference = reference {
        relativePath = reference
    } else {
        relativePath = src
    }
    
    referenceURL = URL(string: relativePath, relativeTo: TranslationCache.sharedInstance.curDirectory)
    
    if referenceURL == nil {
        print("Error: absoluteURL is not a valid URL")
        exit(1)
    }
    
    if let cacheIR = TranslationCache.sharedInstance.irs[referenceURL!] {
        return cacheIR
    }
    
    let ir = tokenizeBuilder(forFormat: describeFormat(forURL: referenceURL!))(FileLoader.loadAndFormat(inputURL: referenceURL!))
    
    if reference != nil {
        let srcURL = URL(string: src, relativeTo: TranslationCache.sharedInstance.curDirectory)
        if TranslationCache.sharedInstance.graph.avoidCycle(from: srcURL!.absoluteString, to: referenceURL!.absoluteString) {
            print("Error: detect a reference cycle from \(srcURL!.absoluteString) to \(referenceURL!.absoluteString)")
            exit(1)
        }
    }
    
    ir.deduce()

    TranslationCache.sharedInstance.irs[referenceURL!] = ir
    return ir
}

func executeBackEndGenerate (ir: IR, outputLanguage: Language, outputDirectory: URL) -> () {
    FileGenerator.generateFile(fileRepresents: codeGenerator(forLanguage: outputLanguage)(ir), outputDirectory: outputDirectory)
}

public func entry(urls: [URL],
                  translationOptions: TranslationOptions,
                  translationOutput: TranslationOutput) {
    
    let recursiveFlag = translationOptions[.recursive] != nil ? true : false
    
    _ = urls.map{(url: URL) -> IR in
        TranslationCache.sharedInstance.curDirectory = url.deletingLastPathComponent()
        return executeFrontEndParse(src: url.lastPathComponent, reference: nil)
    }
    
    TranslationCache.sharedInstance.irs.forEach { (url, ir) in
        if !recursiveFlag &&
            !urls.contains(where: { input -> Bool in
                return input.absoluteString == url.absoluteString
            }) {
            return
        }
        
        translationOutput.forEach({ (element: (key: Language, value: URL)) in
            executeBackEndGenerate(ir: ir, outputLanguage: element.key, outputDirectory: element.value)
        })
    }
}

struct TranslationCache {
    static var sharedInstance = TranslationCache()
    //每个input的当前路径
    var curDirectory: URL?
    //全局IR缓存
    var irs: [URL: IR]
    //全局引用关系图
    var graph: AdjacencyListGraph<String>
    
    fileprivate init() {
        irs = [URL: IR]()
        graph = AdjacencyListGraph<String>()
    }
}

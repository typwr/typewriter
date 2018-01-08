//
//  CLI.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/26.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

fileprivate enum FlagSyntax: String {
    case prefix = "--"
    case equal = "="
    case pwd = "./"
}

fileprivate enum FlagOptions: String {
    case noRecursive = "no_recursive"
    case objcOut = "objc_out"
    case swiftOut = "swift_out"
    case javaOut = "java_out"
    case help = "help"
    
    func needArgument() -> Bool {
        switch self {
        case .noRecursive:
            return false
        case .objcOut:
            return true
        case .swiftOut:
            return true
        case .javaOut:
            return true
        case .help:
            return false
        }
    }
    
    static func helpCommand() -> String {
        return [
            "    --\(FlagOptions.noRecursive.rawValue) - Don't generate files recursively.",
            "    --\(FlagOptions.objcOut.rawValue) - Generate ObjC Code in directory.",
            "    --\(FlagOptions.swiftOut.rawValue) - Generate Swift Code in directory.",
            "    --\(FlagOptions.javaOut.rawValue) - Generate Java Code in directory."
            ].joined(separator: "\n")
    }
}

public func execute(withArgument arguments: [String]) {
    let (flags, args) = parseFlags(arguments: arguments)

    if flags[.help] != nil {
        helpCommand()
        return
    }
    
    guard !args.isEmpty else {
        print("Error: Missing or invalid input")
        return
    }
    
    let urls = args.flatMap{standardizedInputURL(src: $0)}
    
    guard urls.count > 0 else {
        print("Error: Missing or invalid input")
        return
    }
    
    guard flags[.objcOut] != nil || flags[.swiftOut] != nil || flags[.javaOut] != nil else {
        print("Error: Missing or invalid output")
        return
    }
    
    let recursive: String? = flags[.noRecursive] == nil ? .some("recursive") : .none
    
    let translationOptions: TranslationOptions =
        [.recursive: recursive]
        .reduce([:]) { (res, element: (TranslationOption, String?)) in
            var mutableRes = res
            if let value = element.1 {
                mutableRes[element.0] = value
            }
            return mutableRes
        }
    
    let objcOutput: String? = flags[.objcOut] != nil ? .some(flags[.objcOut]!) : .none
    let swiftOutput: String? = flags[.swiftOut] != nil ? .some(flags[.swiftOut]!) : .none
    let javaOutput: String? = flags[.javaOut] != nil ? .some(flags[.javaOut]!) : .none
    
    let translationOutput: TranslationOutput =
        [.ObjC: objcOutput,
         .Swift: swiftOutput,
         .Java: javaOutput]
        .reduce([:]) { (res, element: (Language, String?)) in
            var mutableRes = res
            if let value = element.1, let url = standardizedOutputURL(src: value) {
                mutableRes[element.0] = url
            }
            return mutableRes
        }
    
    guard translationOutput.count > 0 else {
        print("Error: Missing or invalid output")
        return
    }
        
    entry(urls: urls,
          translationOptions: translationOptions,
          translationOutput: translationOutput)
}

fileprivate func helpCommand() {
    let helpDocs = [
        "Usage:",
        "    $ typewriter file1 file2 ... [options]",
        "",
        "Options:",
        "\(FlagOptions.helpCommand())"
        ].joined(separator: "\n")
    
    print(helpDocs)
}

fileprivate func parseFlags(arguments: [String]) -> ([FlagOptions: String], [String]) {
    guard !arguments.isEmpty else {
        return ([:], [])
    }
    
    if let (right, remainingFlag) = parseFlag(arguments: arguments) {
        if remainingFlag.count > 0 {
            let (foldRight, extraFlag) = parseFlags(arguments: remainingFlag)
            if foldRight.count == 0 {
                return (right, extraFlag)
            }
            
            return (foldRight.merging(right, uniquingKeysWith: {(_, new) in new}), extraFlag)
        } else {
            return (right, remainingFlag)
        }
    } else {
        let right = arguments[0]
        let (processedFlag, foldRight) = parseFlags(arguments: Array(arguments[1..<arguments.count]))
        var mutableFoldRight = foldRight
        mutableFoldRight.insert(right, at: 0)
        return (processedFlag, mutableFoldRight)
    }
}

fileprivate func parseFlag(arguments: [String]) -> ([FlagOptions: String], [String])? {
    guard let syntaxCheck = (arguments.first
        .map{$0.components(separatedBy: FlagSyntax.equal.rawValue)[0]}
        .flatMap{
            $0.hasPrefix(FlagSyntax.prefix.rawValue) ?
                $0.replacingOccurrences(of: FlagSyntax.prefix.rawValue, with: "") : nil}) else {
        return nil
    }
    
    guard let flag = FlagOptions(rawValue: syntaxCheck) else {
        print("Error: Unexpected flag \(syntaxCheck)")
        helpCommand()
        exit(1)
    }
    
    if flag.needArgument() {
        let components = arguments[0].components(separatedBy: FlagSyntax.equal.rawValue)
        if components.count == 2 {
            return ([flag: components[1]],
                     Array(arguments[1..<arguments.count]))
        } else if components.count < 2 {
            return ([flag: ""],
                     Array(arguments[1..<arguments.count]))
        } else {
            return ([flag: components.dropFirst().joined(separator: FlagSyntax.equal.rawValue)],
                    Array(arguments[1..<arguments.count]))
        }
    } else {
        return ([flag: ""],
                Array(arguments[1..<arguments.count]))
    }
}

fileprivate func standardizedInputURL(src: String) -> URL? {
    var res: URL?
    let pwd = ProcessInfo.processInfo.environment["PWD"] ?? FileManager.default.currentDirectoryPath
    
    //补全
    if src.hasPrefix(FlagSyntax.pwd.rawValue) {
        res = URL(fileURLWithPath: pwd, isDirectory: false)
        let pathCompletion = String(src[src.index(after: src.index(after: src.startIndex))..<src.endIndex])
        //必须补全
        guard pathCompletion.count > 0 else {
            return nil
        }
        
        res?.appendPathComponent(pathCompletion)
    } else {
        //无需补全
        res = URL(fileURLWithPath: src, isDirectory: false)
    }
    return res
}

fileprivate func standardizedOutputURL(src: String) -> URL? {
    var res: URL?
    let pwd = ProcessInfo.processInfo.environment["PWD"] ?? FileManager.default.currentDirectoryPath
    
    //补全
    if src.hasPrefix(FlagSyntax.pwd.rawValue) {
        res = URL(fileURLWithPath: pwd, isDirectory: true)

        let pathCompletion = String(src[src.index(after: src.index(after: src.startIndex))..<src.endIndex])
        //非必须补全
        if pathCompletion.count > 0 {
            res?.appendPathComponent(pathCompletion)
        }
    } else {
        //无需补全
        res = URL(fileURLWithPath: src, isDirectory: true)
    }
    
    return res
}

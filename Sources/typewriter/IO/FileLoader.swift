//
//  FileLoader.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/6.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct FileLoader {
    static func loadAndFormat(inputURL: URL) -> (String, [String]) {
        do {
            let fileStr = try String(contentsOf: inputURL, encoding: .utf8)
            var lineSeparated = Array<String>()
            
            fileStr.enumerateLines(invoking: { (line, _) in
                lineSeparated.append(line)
            })
            
            let whitespacesLineFree = lineSeparated.filter({ (line) -> Bool in
                return !line.trimmingCharacters(in: .whitespaces).isEmpty
            })
            
            let doubleEndWhitespacesFree = whitespacesLineFree.map{$0.trimmingDoubleEnd()}
            
            let sepacialLineFree = doubleEndWhitespacesFree.filter({ (line) -> Bool in
                if line == "/*" || line == "/**" || line == "*/"
                    || line == "**/" || line == "*" || line == "//" {
                    return false
                }
                return true
            })
            
            return (inputURL.lastPathComponent, sepacialLineFree)
        } catch {
            print("Error: read file from URL -> \(inputURL.absoluteString)")
            exit(1)
        }
        
        return ("", [])
    }    
}

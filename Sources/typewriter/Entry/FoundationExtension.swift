//
//  FoundationExtension.swift
//  typewriter
//
//  Created by mrriddler on 2017/8/24.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

extension Dictionary {
    init(elements: [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

extension String {
    func formatClassName() -> String {
        return replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces)
    }
    
    func objcLiteral() -> String {
        return "@\"\(self)\""
    }
    
    func javaLiteral() -> String {
        return "\"\(self)\""
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
        
    func whitespaces() -> String {
        return String(repeating: " ", count: self.count)
    }
    
    func trimmingLeftEndWhitespaces() -> String {
        if self.hasPrefix(" ") {
            return String(self[self.index(after: self.startIndex)...]).trimmingLeftEndWhitespaces()
        }
        
        return self
    }
    
    func trimmingDoubleEnd() -> String {
        if self.hasPrefix(" ") {
            return String(self[self.index(after: self.startIndex)...]).trimmingDoubleEnd()
        }
        
        if self.hasPrefix("\t") {
            return String(self[self.index(after: self.startIndex)...]).trimmingDoubleEnd()
        }
        
        if self.hasSuffix(" ") {
            return String(self[..<self.index(before: self.endIndex)]).trimmingDoubleEnd()
        }
        
        if self.hasSuffix("\t") {
            return String(self[..<self.index(before: self.endIndex)]).trimmingDoubleEnd()
        }
        
        return self
    }
    
    func findSeparatorRangeInNestedGrammer(beginToken: Character, endToken: Character, separator: Character) -> Range<String.Index>? {
        var stack = [Character]()
        
        for (index, char) in self.enumerated() {
            if char == beginToken {
                stack.append(char)
            } else if char == endToken {
                stack.removeLast()
            } else if char == separator && stack.count == 0 {
                let start = self.index(self.startIndex, offsetBy: index)
                let end = self.index(self.endIndex, offsetBy: index + 1)
                let range = start..<end
                return range
            }
        }
        
        return nil
    }
}

extension Array where Iterator.Element ==  String {
    func removeDuplicate() -> [String] {
        var uniqueSet = Set<String>()
        var des = [String]()
        
        self.forEach { (test) in
            if !uniqueSet.contains(test) {
                uniqueSet.insert(test)
                des.append(test)
            }
        }
        
        return des
    }
    
    func representInFile() -> String {
        return self.map{$0.trimmingCharacters(in: .whitespaces)}
            .filter{!$0.isEmpty}
            .joined(separator: "\n\n")
    }
}

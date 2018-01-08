//
//  Trie.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/21.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

typealias SubTree = (String?, String, [String])

class TrieNode<T: Hashable> {
    var value: T
    weak var parent: TrieNode<T>?
    var childs: LinkedHashMap<T, TrieNode<T>>
    
    var isLeaf: Bool {
        return childs.usageCount == 0
    }
    
    init(value: T, parent: TrieNode<T>? = nil) {
        self.value = value
        self.parent = parent
        self.childs = LinkedHashMap<T, TrieNode<T>>()
    }
    
    func get(value: T) -> TrieNode<T>? {
        return childs[value]
    }
    
    func put(value: T) -> TrieNode<T> {
        let node = TrieNode(value: value, parent: self)
        childs[value] = node
        return node
    }
    
    func delete(value: T) -> Bool {
        return childs.deleteFor(key: value)
    }
    
    func makeSequenceNode() -> [TrieNode<T>]? {
        return childs.makeSequence().map{$0.map{$0.1!}}
    }
    
    func makeSequenceValue() -> [T]? {
        return childs.makeSequence().map{$0.map{$0.0}}
    }
}

class Trie {
    typealias Node = TrieNode<String>
    
    fileprivate var root: Node
    fileprivate let separator: String
    
    init(separator: String, rootValue: String) {
        self.separator = separator
        self.root = Node(value: rootValue)
    }
    
    func contain(path: String) -> Bool {
        return findLeafNode(path: path) != nil
    }
    
    func put(path: String) {
        let pathArr = path.components(separatedBy: separator)
        var cur = root
        
        for section in pathArr {
            if let node = cur.get(value: section) {
                cur = node
            } else {
                let node = cur.put(value: section)
                cur = node
            }
        }
    }
    
    func delete(path: String) -> Bool {
        guard let node = findLeafNode(path: path) else {
            return false
        }
        
        deleteWithLeafNode(node: node)
        return true
    }
    
    func dumpSubTree() -> [SubTree]? {
        var res = [SubTree]()
        var queue = [Node]()
        
        guard let rootSequenceValue = root.makeSequenceValue(), let rootSequenceNode = root.makeSequenceNode() else {
            return nil
        }
        queue.append(contentsOf: rootSequenceNode)
        res.append((nil, root.value, rootSequenceValue))

        while queue.count != 0 {
            let cur = queue.first!
            if let curSequenceValue = cur.makeSequenceValue(), let curSequenceNode = cur.makeSequenceNode() {
                queue.append(contentsOf: curSequenceNode)
                res.append((cur.parent!.value, cur.value, curSequenceValue))
            }
            queue.removeFirst()
        }
        
        return res
    }
    
    fileprivate func findLeafNode(path: String) -> Node? {
        let pathArr = path.components(separatedBy: separator)
        var cur = root
        
        for section in pathArr {
            guard let node = cur.get(value: section) else {
                return nil
            }
            
            cur = node
        }
        
        return cur
    }
    
    fileprivate func deleteWithLeafNode(node: Node) {
        var cur = node
        while cur.isLeaf, let parentNode = cur.parent {
            _ = parentNode.delete(value: cur.value)
            cur = parentNode
        }
    }
}

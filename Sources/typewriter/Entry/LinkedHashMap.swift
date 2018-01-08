//
//  LinkedHashMap.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/21.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

class LinkedHashMapNode<T, U> {
    var key: T
    var value: U?
    weak var pre: LinkedHashMapNode<T, U>?
    weak var next: LinkedHashMapNode<T, U>?
    
    init(key: T, value: U?, pre: LinkedHashMapNode<T, U>? = nil, next: LinkedHashMapNode<T, U>? = nil) {
        self.key = key
        self.value = value
        self.pre = pre
        self.next = next
    }
}

class LinkedHashMap<Key: Hashable, Value> {
    typealias Node = LinkedHashMapNode<Key, Value>
    
    fileprivate var hashMap = [Key: Node]()
    fileprivate var head: Node?
    fileprivate var tail: Node?
    
    var usageCount: Int {
        return hashMap.count
    }
    
    var capacity: Int {
        return hashMap.capacity
    }
    
    subscript(key: Key) -> Value? {
        get {
            return getValueFor(key: key)
        }
        set {
            put(key: key, value: newValue)
        }
    }
    
    func getValueFor(key: Key) -> Value? {
        if let node = hashMap[key] {
            return node.value
        }
        return nil
    }
    
    func put(key: Key, value: Value?) {
        let node = Node(key: key, value: value)
        
        if head == nil {
            head = node
        }
        
        if tail == nil {
            tail = node
        } else {
            tail!.next = node
            node.pre = tail
            tail = node
        }
        
        hashMap[key] = node
    }
    
    func deleteFor(key: Key) -> Bool {
        guard let node = hashMap[key] else {
            return false
        }
        
        if head! === tail! {
            hashMap.removeValue(forKey: key)
            head = nil
            tail = nil
            return true
        }
        
        if node === head! {
            head = head!.next
        } else if node === tail! {
            tail = tail!.pre
        } else {
            node.pre!.next = node.next
            node.next!.pre = node.pre
        }
        hashMap.removeValue(forKey: key)
        
        return true
    }
    
    func makeSequence() -> [(Key, Value?)]? {
        guard head != nil else {
            return nil
        }
        
        var cur = head
        var res = [(Key, Value?)]()
        while cur != nil {
            res.append((cur!.key, cur!.value))
            cur = cur!.next
        }
        
        return res
    }
}

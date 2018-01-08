//
//  AdjacencyListGraph.swift
//  typewriter
//
//  Created by mrriddler on 2017/11/23.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct Vertex<T: Equatable> {
    var value: T
}

extension Vertex: Equatable {
    static func ==<T>(lhs: Vertex<T>, rhs: Vertex<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

struct Edge<T: Equatable> {
    var from: Vertex<T>
    var to: Vertex<T>
}

extension Edge: Equatable {
    static func ==<T>(lhs: Edge<T>, rhs: Edge<T>) -> Bool {
        return (lhs.from == rhs.from) && (lhs.to == rhs.to)
    }
}

class VertexOutDegree<T: Equatable> {
    var vertex: Vertex<T>
    var edges: [Edge<T>] = []
    
    init(vertex: Vertex<T>) {
        self.vertex = vertex
    }
    
    var outDegree: Int {
        return edges.count
    }
    
    func putEdge(edge: Edge<T>) -> Bool {
        guard indexOf(edge: edge) == nil else {
            return false
        }
        
        edges.append(edge)
        return true
    }
    
    func deleteEdge(edge: Edge<T>) -> Bool {
        guard let idx = indexOf(edge: edge) else {
            return false
        }
        
        edges.remove(at: idx)
        return true
    }
    
    fileprivate func indexOf(edge: Edge<T>) -> Int? {
        return edges.index { $0 == edge }
    }
    
    func allAdjacencyVertex() -> [Vertex<T>] {
        var res = [Vertex<T>]()
        
        for element in edges {
            res.append(element.to)
        }
        
        return res
    }
}

class AdjacencyListGraph<T: Equatable> {
    fileprivate var adjacencyList: [VertexOutDegree<T>] = []
    
    func putVertex(value: T) -> Bool {
        guard indexOf(value: value) == nil else {
            return false
        }
        
        let vertexOutDegree = VertexOutDegree<T>(vertex: Vertex<T>(value: value))
        adjacencyList.append(vertexOutDegree)
        return true
    }
    
    func deleteVertex(value: T) -> Bool {
        guard let idx = indexOf(value: value) else {
            return false
        }
        
        adjacencyList.remove(at: idx)
        return true
    }
    
    func putEdge(from: T, to: T) -> Bool {
        guard let idx = indexOf(value: from) else {
            return false
        }
        
        let vertexOutDegree = adjacencyList[idx]
        _ = vertexOutDegree.putEdge(edge: Edge<T>(from: Vertex<T>(value: from), to:  Vertex<T>(value: to)))
        return true
    }
    
    func deleteEdge(from: T, to: T) -> Bool {
        guard let idx = indexOf(value: from) else {
            return false
        }
        
        let vertexOutDegree = adjacencyList[idx]
        _ = vertexOutDegree.deleteEdge(edge: Edge<T>(from: Vertex<T>(value: from), to:  Vertex<T>(value: to)))
        return true
    }
    
    func detectCycle() -> Bool {
        var visited = Array<Bool>(repeating: false, count: adjacencyList.count)
        var pathStack = Array<Bool>(repeating: false, count: adjacencyList.count)

        for (idx, _) in adjacencyList.enumerated() {
            if detectCycleRecursive(curIdx: idx, visited: &visited, pathStack: &pathStack) {
                return true
            }
        }
        
        return false
    }
    
    fileprivate func detectCycleRecursive(curIdx: Int, visited: inout [Bool], pathStack: inout [Bool]) -> Bool {
        if !visited[curIdx] {
            visited[curIdx] = true
            pathStack[curIdx] = true
            
            for element in adjacencyList[curIdx].allAdjacencyVertex() {
                let adjacencyIdx = indexOf(vertex: element)!
                if !visited[adjacencyIdx] && detectCycleRecursive(curIdx: adjacencyIdx, visited: &visited, pathStack: &pathStack) {
                    return true
                } else if pathStack[adjacencyIdx] {
                    return true
                }
            }
        }
        
        pathStack[curIdx] = false
        return false
    }
    
    func avoidCycle(from: T, to: T) -> Bool {
        let fromExists = !putVertex(value: from)
        let toExists = !putVertex(value: to)
        _ = putEdge(from: from, to: to)
        let cycle = detectCycle()
        if fromExists && toExists && cycle {
            _ = deleteEdge(from: from, to: to)
        }
        return cycle
    }
    
    fileprivate func indexOf(value: T) -> Int? {
        return adjacencyList.index { $0.vertex.value == value }
    }
    
    fileprivate func indexOf(vertex: Vertex<T>) -> Int? {
        return adjacencyList.index { $0.vertex.value == vertex.value }
    }
}

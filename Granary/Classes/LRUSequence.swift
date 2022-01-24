//
//  LRUSequence.swift
//  Granary
//
//  Created by Nayanda Haberty on 24/01/22.
//

import Foundation

public class LRUSequence<Key: Hashable, Value>: Lockable {
    
    // MARK: Public Properties
    
    public var keys: [Key] { Array(keyedNodes.keys) }
    public var values: [Value] { keyedNodes.values.map { $0.value } }
    public var count: Int { keyedNodes.count }
    @MoreThanZero public private(set) var costSize: Int = 0
    public let maxCostCapacity: Int
    
    // MARK: Internal Properties
    
    var keyedNodes: [Key: Node] = [:]
    var head: Node? {
        didSet {
            if tail == nil {
                tail = head
            }
        }
    }
    var tail: Node?
    let lock: NSLock = NSLock()
    
    // MARK: Constructor
    
    public init(maxCost: Int) {
        self.maxCostCapacity = Swift.max(0, maxCost)
    }
    
    // MARK: Subscript
    
    public subscript(_ key: Key) -> Value? {
        get {
            getValue(withKey: key)
        } set {
            guard let value = newValue else {
                removeValue(withKey: key)
                return
            }
            store(value, withKey: key)
        }
    }
    
    // MARK: Public Methods
    
    public func store(_ value: Value, withKey key: Key) {
        let valueSize = sizeCost(of: value)
        guard valueSize < maxCostCapacity else { return }
        guard let currentNode = keyedNodes[key] else {
            addNewNode(withValue: value, key: key, costSize: valueSize)
            return
        }
        let oldSize = sizeCost(of: currentNode.value)
        costSize = costSize - oldSize + valueSize
        currentNode.value = value
        moveToHead(for: currentNode)
        removeLeastNodeIfNeeded()
    }
    
    public func getValue(withKey key: Key) -> Value? {
        guard let currentNode = keyedNodes[key] else {
            return nil
        }
        moveToHead(for: currentNode)
        return currentNode.value
    }
    
    @discardableResult
    public func removeValue(withKey key: Key) -> Value? {
        guard let currentNode = keyedNodes[key] else {
            return nil
        }
        let prevNode = currentNode.previous
        let nextNode = currentNode.next
        prevNode?.next = nextNode
        nextNode?.previous = prevNode
        keyedNodes.removeValue(forKey: key)
        if currentNode === head {
            head = nextNode
        }
        if currentNode === tail {
            tail = prevNode
        }
        return currentNode.value
    }
    
    public func removeLeastAccessed() -> Value? {
        let value = tail?.value ?? head?.value
        removeTail()
        return value
    }
    
    // MARK: Private Methods
    
    private func sizeCost(of object: Value) -> Int {
        guard let calculatable = object as? LRUCostCalculatable else {
            return MemoryLayout.size(ofValue: object)
        }
        return calculatable.sizeCost
    }
    
    private func addNewNode(withValue value: Value, key: Key, costSize: Int) {
        let newNode = Node(key: key, value: value, next: head)
        let oldHead = head
        oldHead?.previous = newNode
        head = newNode
        keyedNodes[key] = newNode
        removeLeastNodeIfNeeded()
    }
    
    private func moveToHead(for node: LRUSequence<Key, Value>.Node) {
        let prevNode = node.previous
        let nextNode = node.next
        prevNode?.next = nextNode
        nextNode?.previous = prevNode
        head?.previous = node
        node.previous = nil
        node.next = head
        head = node
    }
    
    private func removeLeastNodeIfNeeded() {
        while costSize > maxCostCapacity {
            removeTail()
        }
    }
    
    private func removeTail() {
        guard let tailNode = tail else {
            return
        }
        let tailSize = sizeCost(of: tailNode.value)
        costSize -= tailSize
        let prevNode = tailNode.previous
        prevNode?.next = nil
        tail = prevNode
        keyedNodes.removeValue(forKey: tailNode.key)
    }
}

// MARK: LRUSequence Node

extension LRUSequence {
    class Node {
        var previous: Node?
        var next: Node?
        var value: Value
        let key: Key
        
        init(key: Key, value: Value, previous: LRUSequence<Key, Value>.Node? = nil, next: LRUSequence<Key, Value>.Node? = nil) {
            self.key = key
            self.value = value
            self.previous = previous
            self.next = next
        }
    }
}

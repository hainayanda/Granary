//
//  LRUSequence.swift
//  Granary
//
//  Created by Nayanda Haberty on 24/01/22.
//

import Foundation

public protocol LRUSequenceEventListener: AnyObject {
    func lru(sender: AnyObject, willReplace value: Any, withNewValue newValue: Any, withKey key: AnyHashable)
    func lru(sender: AnyObject, didReplace value: Any, withNewValue newValue: Any, withKey key: AnyHashable)
    func lru(sender: AnyObject, willAdd value: Any, withKey key: AnyHashable)
    func lru(sender: AnyObject, didAdd value: Any, withKey key: AnyHashable)
    func lru(sender: AnyObject, willRemove value: Any, withKey key: AnyHashable)
    func lru(sender: AnyObject, didRemove value: Any, withKey key: AnyHashable)
    func lruWillClear(sender: AnyObject)
    func lruDidClear(sender: AnyObject)
}

public extension LRUSequenceEventListener {
    func lru(sender: AnyObject, willReplace value: Any, withNewValue newValue: Any, withKey key: AnyHashable) { }
    func lru(sender: AnyObject, didReplace value: Any, withNewValue newValue: Any, withKey key: AnyHashable) { }
    func lru(sender: AnyObject, willAdd value: Any, withKey key: AnyHashable) { }
    func lru(sender: AnyObject, didAdd value: Any, withKey key: AnyHashable) { }
    func lru(sender: AnyObject, willRemove value: Any, withKey key: AnyHashable) { }
    func lru(sender: AnyObject, didRemove value: Any, withKey key: AnyHashable) { }
    func lruWillClear(sender: AnyObject) { }
    func lruDidClear(sender: AnyObject) { }
}

public class LRUSequence<Key: Hashable, Value>: Cache, Lockable {
    
    // MARK: Public Properties
    
    public var keys: [Key] { Array(keyedNodes.keys) }
    public var values: [Value] { keyedNodes.values.map { $0.value } }
    public var dictionary: [Key: Value] { keyedNodes.mapValues { $0.value } }
    public var count: Int { keyedNodes.count }
    public weak var listener: LRUSequenceEventListener?
    
    // MARK: Internal Properties
    
    var costManager: LRUCostManager
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
    
    init(costManager: LRUCostManager) {
        self.costManager = costManager
    }
    
    // MARK: Public Methods
    
    public func store(_ value: Value, withKey key: Key) {
        lockedRun {
            guard !costManager.isCostTooMuch(for: value, keyedBy: key) else { return }
            guard let currentNode = keyedNodes[key] else {
                listener?.lru(sender: self, willAdd: value, withKey: key)
                addNewNode(withValue: value, key: key)
                listener?.lru(sender: self, didAdd: value, withKey: key)
                return
            }
            let oldValue = currentNode.value
            listener?.lru(sender: self, willReplace: oldValue, withNewValue: value, withKey: key)
            costManager.susbstractToTotalCost(for: oldValue, keyedBy: key)
            costManager.addToTotalCost(for: value, keyedBy: key)
            currentNode.value = value
            moveToHead(for: currentNode)
            removeLeastNodeIfNeeded()
            listener?.lru(sender: self, didReplace: oldValue, withNewValue: value, withKey: key)
        }
    }
    
    public func value(withKey key: Key) -> Value? {
        lockedRun {
            guard let currentNode = keyedNodes[key] else {
                return nil
            }
            moveToHead(for: currentNode)
            return currentNode.value
        }
    }
    
    @discardableResult
    public func removeValue(withKey key: Key) -> Value? {
        lockedRun {
            guard let currentNode = keyedNodes[key] else {
                return nil
            }
            listener?.lru(sender: self, willRemove: currentNode.value, withKey: key)
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
            listener?.lru(sender: self, didRemove: currentNode.value, withKey: key)
            return currentNode.value
        }
    }
    
    public func removeLeastAccessedValue() -> Value? {
        lockedRun {
            let value = tail?.value ?? head?.value
            removeTail()
            return value
        }
    }
    
    public func clear() {
        lockedRun {
            listener?.lruWillClear(sender: self)
            head = nil
            tail = nil
            keyedNodes = [:]
            listener?.lruDidClear(sender: self)
        }
    }
    
    // MARK: Private Methods
    
    private func addNewNode(withValue value: Value, key: Key) {
        let newNode = Node(key: key, value: value, next: head)
        let oldHead = head
        oldHead?.previous = newNode
        head = newNode
        keyedNodes[key] = newNode
        costManager.addToTotalCost(for: value, keyedBy: key)
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
        while costManager.exceededTotalCost {
            removeTail()
        }
    }
    
    private func removeTail() {
        guard let tailNode = tail else {
            return
        }
        listener?.lru(sender: self, willRemove: tailNode.value, withKey: tailNode.key)
        costManager.susbstractToTotalCost(for: tailNode.value, keyedBy: tailNode.key)
        let prevNode = tailNode.previous
        prevNode?.next = nil
        tail = prevNode
        keyedNodes.removeValue(forKey: tailNode.key)
        listener?.lru(sender: self, didRemove: tailNode.value, withKey: tailNode.key)
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

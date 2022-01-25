//
//  CostManager.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

public protocol LRUCostManager {
    var exceededTotalCost: Bool { get }
    func isCostTooMuch(for value: Any, keyedBy key: AnyHashable) -> Bool
    func addToTotalCost(for value: Any, keyedBy key: AnyHashable)
    func susbstractToTotalCost(for value: Any, keyedBy key: AnyHashable)
}

public protocol LRUKeyValueCostManager: LRUCostManager {
    associatedtype Key: Hashable
    associatedtype Value
    func isCostTooMuch(forValue value: Value, keyedBy key: Key) -> Bool
    func addToTotalCost(forValue value: Value, keyedBy key: Key)
    func susbstractToTotalCost(forValue value: Value, keyedBy key: Key)
}

public extension LRUKeyValueCostManager {
    func isCostTooMuch(for value: Any, keyedBy key: AnyHashable) -> Bool {
        guard let value = value as? Value, let thisKey = key as? Key else { return true }
        return isCostTooMuch(forValue: value, keyedBy: thisKey)
    }
    
    func addToTotalCost(for value: Any, keyedBy key: AnyHashable) {
        guard let value = value as? Value, let thisKey = key as? Key else { return }
        addToTotalCost(forValue: value, keyedBy: thisKey)
    }
    
    func susbstractToTotalCost(for value: Any, keyedBy key: AnyHashable) {
        guard let value = value as? Value, let thisKey = key as? Key else { return }
        susbstractToTotalCost(forValue: value, keyedBy: thisKey)
    }
}

public class LRUCalculatableCostManager<Key: Hashable, Value: CacheCalculatableCost>: LRUKeyValueCostManager {
    
    public let maximumCost: Int
    public private(set) var currentCost: Int = 0
    
    public init(maximumCost: Int) {
        self.maximumCost = maximumCost
    }
    
    public var exceededTotalCost: Bool {
        currentCost > maximumCost
    }
    
    public func isCostTooMuch(forValue value: Value, keyedBy key: Key) -> Bool {
        value.sizeCost > maximumCost
    }
    
    public func addToTotalCost(forValue value: Value, keyedBy key: Key) {
        currentCost += value.sizeCost
    }
    
    public func susbstractToTotalCost(forValue value: Value, keyedBy key: Key) {
        currentCost -= value.sizeCost
    }
}

//
//  LRUCache.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

public class LRUCache<Key: CacheFileNameConvertible, Value: Archivable>: Cache {
    let inMemoryCache: LRUSequence<Key, Value>
    let inDiskCache: LRUDiskSequence<Key, Value>?
    
    init(costManager: LRUCostManager, maxDiskDataSize: DataSize) {
        inMemoryCache = LRUSequence(costManager: costManager)
        do {
            inDiskCache = try LRUDiskSequence(maxDataSize: maxDiskDataSize)
        } catch {
            inDiskCache = nil
            print("error")
        }
    }
    
    public func store(_ value: Value, withKey key: Key) {
        inMemoryCache.store(value, withKey: key)
        inDiskCache?.store(value, withKey: key)
    }
    
    public func value(withKey key: Key) -> Value? {
        guard let value = inMemoryCache.value(withKey: key) else {
            guard let value = inDiskCache?.value(withKey: key) else {
                return nil
            }
            inMemoryCache.store(value, withKey: key)
            return value
        }
        return value
    }
    
    public func removeValue(withKey key: Key) -> Value? {
        let memoryValue = inMemoryCache.removeValue(withKey: key)
        let diskValue = inDiskCache?.removeValue(withKey: key)
        return memoryValue ?? diskValue
    }
    
    public func clear() {
        inMemoryCache.clear()
        inDiskCache?.clear()
    }
}

extension LRUCache where Value: CacheCalculatableCost {
    convenience init(maxDiskDataSize: DataSize) {
        let memoryMaxSize = Int(maxDiskDataSize.bytes / 2)
        self.init(
            costManager: LRUCalculatableCostManager<Key, Value>(maximumCost: memoryMaxSize),
            maxDiskDataSize: maxDiskDataSize
        )
    }
}

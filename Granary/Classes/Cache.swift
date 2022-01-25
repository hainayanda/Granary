//
//  Cache.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

public protocol Cache {
    associatedtype Value
    associatedtype Key: Hashable
    
    subscript(_ key: Key) -> Value? { get set }
    
    func store(_ value: Value, withKey key: Key)
    func value(withKey key: Key) -> Value?
    @discardableResult
    func removeValue(withKey key: Key) -> Value?
    func clear()
}

extension Cache {
    public subscript(_ key: Key) -> Value? {
        get {
            value(withKey: key)
        } set {
            guard let value = newValue else {
                removeValue(withKey: key)
                return
            }
            store(value, withKey: key)
        }
    }
}

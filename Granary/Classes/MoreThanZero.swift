//
//  AbsoluteInt.swift
//  Granary
//
//  Created by Nayanda Haberty on 24/01/22.
//

import Foundation

@propertyWrapper
public struct MoreThanZero {
    private var _wrappedValue: Int
    public var wrappedValue: Int {
        get {
            _wrappedValue
        }
        set {
            _wrappedValue = Swift.max(newValue, 0)
        }
    }
    
    public init(wrappedValue: Int) {
        self._wrappedValue = wrappedValue
    }
}

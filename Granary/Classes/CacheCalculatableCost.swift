//
//  LRUCostCalculatable.swift
//  Granary
//
//  Created by Nayanda Haberty on 24/01/22.
//

import Foundation

public protocol CacheCalculatableCost {
    var sizeCost: Int { get }
}

extension String: CacheCalculatableCost {
    public var sizeCost: Int {
        count
    }
}

extension Data: CacheCalculatableCost {
    public var sizeCost: Int {
        count
    }
}

extension CacheCalculatableCost where Self: Encodable {
    public var sizeCost: Int {
        do {
            return try JSONEncoder().encode(self).sizeCost
        } catch {
            return MemoryLayout.size(ofValue: self)
        }
    }
}

#if canImport(UIKit)
import UIKit

extension UIImage: CacheCalculatableCost {
    public var sizeCost: Int {
        UIImagePNGRepresentation(self)?.count ?? 0
    }
}
#endif

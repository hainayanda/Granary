//
//  LRUCostCalculatable.swift
//  Granary
//
//  Created by Nayanda Haberty on 24/01/22.
//

import Foundation

public protocol LRUCostCalculatable {
    var sizeCost: Int { get }
}

extension String: LRUCostCalculatable {
    public var sizeCost: Int {
        count
    }
}

extension Data: LRUCostCalculatable {
    public var sizeCost: Int {
        count
    }
}

#if canImport(UIKit)
import UIKit

extension UIImage: LRUCostCalculatable {
    public var sizeCost: Int {
        UIImagePNGRepresentation(self)?.count ?? 0
    }
}
#endif

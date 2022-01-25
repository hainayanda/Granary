//
//  CacheFileNameConvertible.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

public protocol CacheFileNameConvertible: Hashable {
    var asCacheFileName: String { get }
    static func convertBack(from fileName: String) -> Self
}

extension String: CacheFileNameConvertible {
    
    public var asCacheFileName: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    }
    
    public static func convertBack(from fileName: String) -> String {
        fileName.removingPercentEncoding ?? ""
    }
}

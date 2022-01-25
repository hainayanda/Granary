//
//  Archivable.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

public protocol Archivable {
    static var archiveGroupName: String { get }
    
    static func decode(archive data: Data) throws -> Self
    func archive() throws -> Data
}

public extension Archivable {
    static var archiveGroupName: String {
        let camelCase = String(describing: Self.self)
            .filter { $0.isLetter || $0.isNumber }
            .camelCaseToSnakeCase()
        return "granary_\(camelCase)"
    }
}

public extension Archivable where Self: Codable {
    func archive() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    static func decode(archive data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}

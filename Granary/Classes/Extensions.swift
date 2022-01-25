//
//  Extensions.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

extension String {
    func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self.processCamelCase(pattern: acronymPattern)?
            .processCamelCase(pattern: normalPattern)?.lowercased() ?? self.lowercased()
    }
    
    private func processCamelCase(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}

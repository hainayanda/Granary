//
//  GranaryError.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

/// Error object generated from Granary
public struct GranaryError: LocalizedError {
    
    /// Description of error
    public let errorDescription: String?
    
    /// Reason of failure
    public let failureReason: String?
    
    init(errorDescription: String, failureReason: String? = nil) {
        self.errorDescription = errorDescription
        self.failureReason = failureReason
    }
}

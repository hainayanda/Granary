//
//  ByteSize.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

public struct DataSize: Equatable {
    
    public var bits: UInt64 { bytes * 8 }
    public var nibbles: UInt64 { bytes * 2 }
    public var bytes: UInt64
    public var kiloBytes: Double {
        let bytes: Double = Double(self.bytes)
        return bytes / 1024
    }
    public var megaBytes: Double {
        return kiloBytes / 1024
    }
    public var gigaBytes: Double {
        return megaBytes / 1024
    }
    
    public static var zero: DataSize {
        .init(bytes: 0)
    }
    
    public static func bits(_ count: UInt64) -> DataSize {
        let bytes = count / 8
        if count % 8 == 0 {
            return .init(bytes: bytes)
        }
        return .init(bytes: bytes + 1)
    }
    
    public static func nibbles(_ count: UInt64) -> DataSize {
        let numberOfBits = count * 4
        return .bits(numberOfBits)
    }
    
    public static func bytes(_ count: UInt64) -> DataSize {
        .init(bytes: count)
    }
    
    public static func kiloBytes(_ count: UInt64) -> DataSize {
        .init(bytes: count * 1024)
    }
    
    public static func kiloBytes(_ count: Double) -> DataSize {
        let numberOfBits = abs(count * 8 * 1024)
        return .bits(UInt64(numberOfBits))
    }
    
    public static func megaBytes(_ count: UInt64) -> DataSize {
        .init(bytes: count * 1024 * 1024)
    }
    
    public static func megaBytes(_ count: Double) -> DataSize {
        let numberOfBits = abs(count * 8 * 1024 * 1024)
        return .bits(UInt64(numberOfBits))
    }
    
    public static func gigaBytes(_ count: UInt64) -> DataSize {
        .init(bytes: count * 1024 * 1024 * 1024)
    }
    
    public static func gigaBytes(_ count: Double) -> DataSize {
        let numberOfBits = abs(count * 8 * 1024 * 1024 * 1024)
        return .bits(UInt64(numberOfBits))
    }
}

extension DataSize: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt64
    
    public init(integerLiteral value: UInt64) {
        self.init(bytes: value)
    }
}

extension DataSize: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    
    public init(floatLiteral value: Double) {
        let numberOfBits = abs(value * 8)
        var bytes: UInt64 = UInt64(numberOfBits / 8)
        if numberOfBits.truncatingRemainder(dividingBy: 8) > 0 {
            bytes += 1
        }
        self.init(bytes: bytes)
    }
}

extension DataSize: Comparable {
    
    public static func < (lhs: DataSize, rhs: DataSize) -> Bool {
        return lhs.bytes < rhs.bytes
    }
}

extension DataSize: AdditiveArithmetic {
    public static func - (lhs: DataSize, rhs: DataSize) -> DataSize {
        return .init(bytes: lhs.bytes - rhs.bytes)
    }
    
    public static func + (lhs: DataSize, rhs: DataSize) -> DataSize {
        return .init(bytes: lhs.bytes + rhs.bytes)
    }
}

extension Int {
    public var bits: DataSize { .bits(UInt64(self)) }
    public var nibbles: DataSize { .nibbles(UInt64(self)) }
    public var bytes: DataSize { .init(bytes: UInt64(self)) }
    public var kiloBytes: DataSize { .kiloBytes(UInt64(self)) }
    public var megaBytes: DataSize { .megaBytes(UInt64(self)) }
    public var gigaBytes: DataSize { .gigaBytes(UInt64(self)) }
}

extension Double {
    public var kiloBytes: DataSize { .kiloBytes(self) }
    public var megaBytes: DataSize { .megaBytes(self) }
    public var gigaBytes: DataSize { .gigaBytes(self) }
}

extension Data {
    public var dataSize: DataSize {
        .init(bytes: UInt64(count))
    }
}

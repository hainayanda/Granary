//
//  Lockable.swift
//  Granary
//
//  Created by Nayanda Haberty on 24/01/22.
//

import Foundation

protocol Lockable {
    var lock: NSLock { get }
}

extension Lockable {
    func lockedRun<R>(_ task: () -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return task()
    }
}

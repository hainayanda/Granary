//
//  LRUDiskSequence.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

public class LRUDiskSequence<Key: CacheFileNameConvertible, Value: Archivable>: Cache, Lockable, LRUCostManager {
    var lock: NSLock = NSLock()
    let maxDataSize: DataSize
    private(set) var currentDataSize: DataSize = 0.bytes
    let diskManager: DiskManager
    private(set) lazy var lruIndex: LRUSequence<Key, String> = LRUSequence(costManager: self)
    
    init(maxDataSize: DataSize) throws {
        self.maxDataSize = maxDataSize
        guard let path = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory,
            .userDomainMask, true
        ).first as NSString? else {
            throw GranaryError(
                errorDescription: "GranaryError: fail creating DiskArchiver",
                failureReason: "Fail to get chaches directory"
            )
        }
        diskManager = try DiskCacheManager(diskStringPath: path.appendingPathComponent(Value.archiveGroupName))
        currentDataSize = diskManager.directorySize
        lruIndex.listener = self
        diskManager.filesNames.forEach {
            lruIndex.store($0, withKey: Key.convertBack(from: $0))
        }
    }
    
    // MARK: Public Method
    
    public func store(_ value: Value, withKey key: Key) {
        lockedRun {
            let fileName = key.asCacheFileName
            guard let data = try? value.archive() else { return }
            if diskManager.isFileExist(forName: fileName) {
                try? diskManager.deleteFile(named: fileName)
            }
            diskManager.createFile(named: fileName, contents: data)
            lruIndex.store(fileName, withKey: key)
        }
    }
    
    public func value(withKey key: Key) -> Value? {
        lockedRun {
            guard let fileName = lruIndex.value(withKey: key),
                  let data = try? diskManager.readFile(named: fileName),
                  let value = try? Value.decode(archive: data) else {
                      return nil
                  }
            try? diskManager.updateDate(forFileName: fileName)
            return value
        }
    }
    
    public func removeValue(withKey key: Key) -> Value? {
        lockedRun {
            let fileName = key.asCacheFileName
            guard let data = try? diskManager.readFile(named: fileName),
                  let value = try? Value.decode(archive: data) else { return nil }
            lruIndex.removeValue(withKey: key)
            return value
        }
    }
    
    public func clear() {
        lockedRun {
            lruIndex.clear()
        }
    }
}

extension LRUDiskSequence: LRUSequenceEventListener {
    
    public func lru(sender: AnyObject, didRemove value: Any, withKey key: AnyHashable) {
        lockIfNotLocked {
            guard let fileName = (key as? Key)?.asCacheFileName else { return }
            try? diskManager.deleteFile(named: fileName)
        }
    }
    
    public func lruDidClear(sender: AnyObject) {
        lockIfNotLocked {
            diskManager.clearDirectory()
        }
    }
}

extension LRUDiskSequence: LRUKeyValueCostManager {
    public func isCostTooMuch(forValue value: Value, keyedBy key: Key) -> Bool {
        do {
            return try value.archive().dataSize > maxDataSize
        } catch {
            return true
        }
    }
    
    public func addToTotalCost(forValue value: Value, keyedBy key: Key) {
        do {
            let size: DataSize
            if let fileSize = diskManager.size(ofFile: key.asCacheFileName) {
                size = fileSize
            } else {
                size = try value.archive().dataSize
            }
            currentDataSize += size
        } catch {
            return
        }
    }
    
    public func susbstractToTotalCost(forValue value: Value, keyedBy key: Key) {
        do {
            let size: DataSize
            if let fileSize = diskManager.size(ofFile: key.asCacheFileName) {
                size = fileSize
            } else {
                size = try value.archive().dataSize
            }
            currentDataSize -= size
        } catch {
            return
        }
    }
    
    public var exceededTotalCost: Bool {
        currentDataSize > maxDataSize
    }
}


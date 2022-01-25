//
//  DiskCacheManager.swift
//  Granary
//
//  Created by Nayanda Haberty on 25/01/22.
//

import Foundation

protocol DiskManager {
    var filesNames: [String] { get }
    var directorySize: DataSize { get }
    func clearDirectory()
    func size(ofFile fileName: String) -> DataSize?
    func isFileExist(forName fileName: String) -> Bool
    func createFile(named fileName: String, contents: Data)
    func readFile(named fileName: String) throws -> Data
    func deleteFile(named fileName: String) throws
    func updateDate(forFileName fileName: String) throws
}

class DiskCacheManager: DiskManager {
    lazy var fileManager: FileManager = .default
    let diskStringPath: String
    let diskUrlPath: URL
    let fileExtension: String = "grn"
    var filesNames: [String] {
        let contents = try? fileManager.contentsOfDirectory(
            at: diskUrlPath,
            includingPropertiesForKeys: nil,
            options: .skipsSubdirectoryDescendants
        )
        return (contents ?? []).filter {
            $0.pathExtension == fileExtension
        }.compactMap {
            $0.deletingPathExtension().lastPathComponent
        }.sorted {
            fileLatestUpdate(named: $0) > fileLatestUpdate(named: $1)
        }
    }
    
    var directorySize: DataSize {
        fileURLs.reduce(0.bytes) { partialResult, url in
            do {
                let resource = try url.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
                let size = resource.fileSize ?? 0
                return partialResult + size.bytes
            } catch {
                return partialResult
            }
        }
    }
    
    private var fileURLs: [URL] {
        let contents = try? fileManager.contentsOfDirectory(
            at: diskUrlPath,
            includingPropertiesForKeys: nil,
            options: .skipsSubdirectoryDescendants
        )
        return contents ?? []
    }
    
    init(diskStringPath: String) throws {
        self.diskStringPath = diskStringPath
        self.diskUrlPath = URL(fileURLWithPath: diskStringPath)
        guard isDirectoryExist(forPath: diskStringPath) else {
            try createDirectory(at: diskUrlPath)
            return
        }
    }
    
    // MARK: Directory Operation
    
    func isDirectoryExist(forPath path: String) -> Bool {
        var isDirectory : ObjCBool = false
        let isExist = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue && isExist
    }
    
    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    
    func clearDirectory() {
        filesNames.forEach {
            try? deleteFile(named: $0)
        }
    }
    
    // MARK: File Operation
    
    func size(ofFile fileName: String) -> DataSize? {
        do {
            let path: URL = URL(fileURLWithPath: filePath(ofFileName: fileName))
            let resource = try path.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
            let size = resource.fileSize ?? 0
            return size.bytes
        } catch {
            return nil
        }
    }
    
    func isFileExist(forName fileName: String) -> Bool {
        var isDirectory : ObjCBool = false
        let isExist = fileManager.fileExists(
            atPath: filePath(ofFileName: fileName),
            isDirectory: &isDirectory
        )
        return !isDirectory.boolValue && isExist
    }
    
    func createFile(named fileName: String, contents: Data) {
        fileManager.createFile(
            atPath: filePath(ofFileName: fileName),
            contents: contents,
            attributes: [.creationDate: Date() as NSDate]
        )
    }
    
    func readFile(named fileName: String) throws -> Data {
        let url = URL(fileURLWithPath: filePath(ofFileName: fileName))
        return try Data(contentsOf: url)
    }
    
    func deleteFile(named fileName: String) throws {
        try fileManager.removeItem(atPath: filePath(ofFileName: fileName))
    }
    
    func updateDate(forFileName fileName: String) throws {
        try fileManager.setAttributes(
            [.modificationDate: Date() as NSDate],
            ofItemAtPath: filePath(ofFileName: fileName)
        )
    }
    
    func populateFileName(at path: String) throws -> [String] {
        let url = URL(fileURLWithPath: path)
        let contents = try fileManager.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil,
            options: .skipsSubdirectoryDescendants
        )
        return contents.filter {
            $0.pathExtension == fileExtension
        }.compactMap {
            $0.deletingPathExtension().lastPathComponent
        }
    }
    
    // MARK: Private Method
    
    private func filePath(ofFileName fileName: String) -> String {
        (diskStringPath as NSString).appendingPathComponent("\(fileName).\(fileExtension)")
    }
    
    private func fileLatestUpdate(named fileName: String) -> Date {
        let attributes = try? fileManager.attributesOfItem(atPath: filePath(ofFileName: fileName))
        let creationDate = (attributes?[.creationDate] as? NSDate) as Date? ?? .distantPast
        let modifyDate = (attributes?[.modificationDate] as? NSDate) as Date? ?? .distantPast
        return max(creationDate, modifyDate)
    }
    
}

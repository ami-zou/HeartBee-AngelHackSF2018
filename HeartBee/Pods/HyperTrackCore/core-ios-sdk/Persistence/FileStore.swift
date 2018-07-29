//
//  FileStore.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 06/06/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//
// Reference: https://medium.com/@sdrzn/swift-4-codable-lets-make-things-even-easier-c793b6cf29e1

import Foundation

protocol AbstractFileStorage: class {
    func store<T: Encodable>(_ object: T, to directory: FileStorage.Directory, as fileName: String)
    func retrieve<T: Decodable>(_ fileName: String, from directory: FileStorage.Directory, as type: T.Type) -> T?
    func retrieve<T: Decodable>(_ filePath: String, as type: T.Type) -> T?
    func remove(_ fileName: String, from directory: FileStorage.Directory)
    func clear(_ directory: FileStorage.Directory)
}

public final class FileStorage: AbstractFileStorage {
    fileprivate weak var logger: AbstractLogger?
    
    init(_ logger: AbstractLogger?) {
        self.logger = logger
    }
    
    enum Directory {
        // Only documents and other data that is user-generated, or that cannot otherwise be recreated by your application, should be stored in the <Application_Home>/Documents directory and will be automatically backed up by iCloud.
        case documents
        
        // Data that can be downloaded again or regenerated should be stored in the <Application_Home>/Library/Caches directory. Examples of files you should put in the Caches directory include database cache files and downloadable content, such as that used by magazine, newspaper, and map applications.
        case caches
    }
    
    /// Returns URL constructed from specified directory
    fileprivate func getURL(for directory: Directory) -> URL? {
        var searchPathDirectory: FileManager.SearchPathDirectory
        
        switch directory {
        case .documents:
            searchPathDirectory = .documentDirectory
        case .caches:
            searchPathDirectory = .cachesDirectory
        }
        
        if let url = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first {
            return url
        } else {
            logger?.logError("Could not create URL for specified directory", context: Constant.Context.fileStorage)
            return nil
        }
    }
    
    
    /// Store an encodable struct to the specified directory on disk
    ///
    /// - Parameters:
    ///   - object: the encodable struct to store
    ///   - directory: where to store the struct
    ///   - fileName: what to name the file where the struct data will be stored
    func store<T: Encodable>(_ object: T, to directory: Directory, as fileName: String) {
        guard let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) else {
            logger?.logError("Could not find the specified directory", context: Constant.Context.fileStorage)
            return
        }
        
        let encoder = JSONEncoder.hyperTrackEncoder
        do {
            let data = try encoder.encode(object)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
        } catch let error {
            logger?.logError("Failed to store file because \(error.coreErrorDescription)", context: Constant.Context.fileStorage)
        }
    }
    
    /// Retrieve and convert a struct from a file on disk
    ///
    /// - Parameters:
    ///   - fileName: name of the file where struct data is stored
    ///   - directory: directory where struct data is stored
    ///   - type: struct type (i.e. Message.self)
    /// - Returns: decoded struct model(s) of data
    func retrieve<T: Decodable>(_ fileName: String, from directory: Directory, as type: T.Type) -> T? {
        guard let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) else {
            logger?.logError("Could not find \(fileName) in the specified directory", context: Constant.Context.fileStorage)
            return nil
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            logger?.logError("File at path \(url.path) does not exist", context: Constant.Context.fileStorage)
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder.hyperTrackDecoder
            do {
                let model = try decoder.decode(type, from: data)
                return model
            } catch {
                logger?.logError(error.localizedDescription, context: Constant.Context.fileStorage)
            }
        } else {
            logger?.logError("No data at \(url.path)!", context: Constant.Context.fileStorage)
        }
        return nil
    }
    
    func retrieve<T>(_ filePath: String, as type: T.Type) -> T? where T : Decodable {
        guard let data = FileManager.default.contents(atPath: filePath) else {
            logger?.logError("Unable to parse data from file \(filePath)", context: Constant.Context.fileStorage)
            return nil
        }
        do {
            if filePath.contains("plist") {
                return try PropertyListDecoder().decode(type, from: data)
            } else {
                return try JSONDecoder().decode(type, from: data)
            }
            
        } catch {
            logger?.logError("Could not read from file", context: Constant.Context.config)
        }
        return nil
    }
    
    /// Remove all files at specified directory
    func clear(_ directory: Directory) {
        guard let url = getURL(for: directory) else {
            logger?.logError("Could not find the specified directory", context: Constant.Context.fileStorage)
            return
        }
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for fileUrl in contents {
                try FileManager.default.removeItem(at: fileUrl)
            }
        } catch let error {
            logger?.logError("Failed to remove all files because \(error.coreErrorDescription)", context: Constant.Context.fileStorage)
        }
    }
    
    /// Remove specified file from specified directory
    func remove(_ fileName: String, from directory: Directory) {
        guard let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) else {
            logger?.logError("Could not find \(fileName) in the specified directory", context: Constant.Context.fileStorage)
            return
        }
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                logger?.logError(error.localizedDescription, context: Constant.Context.fileStorage)
            }
        }
    }
    
    /// Returns BOOL indicating whether file exists at specified directory with specified file name
    fileprivate func fileExists(_ fileName: String, in directory: Directory) -> Bool {
        guard let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) else {
            logger?.logError("Could not find \(fileName) in the specified directory", context: Constant.Context.fileStorage)
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

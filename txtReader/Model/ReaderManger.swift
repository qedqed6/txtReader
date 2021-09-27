//
//  TextReaderManger.swift
//  txtReader
//
//  Created by peter on 2021/9/20.
//

import Foundation
import UIKit

let fileManger = FileManager.default

enum CodingFormat: Codable, Equatable {
    case utf8
    case big5
    case big5_HKSCS_1999
    case GB_18030_2000
}

struct ReaderItemFile: Codable, Equatable {
    var rowText: [String] = []
}

struct ReaderItem: Codable, Equatable {
    var name: String = ""
    var coding: CodingFormat = .utf8
    var readRows = 0
    var totalRows = 0
}

struct ReaderItemList: Codable, Equatable {
    var items: [ReaderItem] = []
    
    func itemName() -> [String] {
        self.items.compactMap { $0.name }
    }
    
    func firstIndex(of name: String) -> Int? {
        items.firstIndex { $0.name == name }
    }
    
    func firstItem(of name: String) -> ReaderItem? {
        guard let index = (items.firstIndex { $0.name == name }) else {
            return nil
        }
        return items[index]
    }
    
    mutating func removalAll(name: [String], _ handle: ((ReaderItem) -> Void)?) {
        let index = items.halfStablePartition {
            name.firstIndex(of: $0.name) != nil
        }
        if index >= items.count {
            return
        }
        
        for index in index..<items.count {
            handle?(items[index])
        }
        items.removeSubrange(index..<items.count)
    }
    
    mutating func appendAll(name: [String], _ handle: ((ReaderItem) -> Void)?) {
        for name in name {
            let item = ReaderItem(name: name)
            handle?(item)
            items.append(item)
        }
    }
}

class ReaderManger {
    static let share = ReaderManger()
    
    private let folderName = "data"
    private let itemFolderName = "items"
    private let listFileName = "list.info"
    
    private let documentURL: URL
    private let folderURL: URL
    private let itemFolderURL: URL
    private let listFileURL: URL
    
    private let fileManger = FileManager.default
    private let queue = DispatchQueue(label: "com.qedqed6.queue")
    
    private let fileQueue = DispatchQueue(label: "com.qedqed6.fileQueue")
    private var innerItemList: ReaderItemList? = nil
    private var itemList: ReaderItemList? {
        get { innerItemList }
        set {
            if innerItemList != newValue {
                innerItemList = newValue
                itemListFile = newValue
            }
        }
    }
    
    private init() {
        guard let documentDirectoryURL = fileManger.documentDirectoryURL else {
            fatalError("Document Directory doesn't exist !")
        }
        
        documentURL = documentDirectoryURL
        folderURL = documentURL.appendingPathComponent(folderName, isDirectory: true)
        itemFolderURL = folderURL.appendingPathComponent(itemFolderName, isDirectory: true)
        listFileURL = folderURL.appendingPathComponent(listFileName, isDirectory: false)
        
        print(folderURL)
        
        do {
            if fileManger.fileNotExists(atPath: folderURL.path) {
                try fileManger.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            if fileManger.fileNotExists(atPath: itemFolderURL.path) {
                try fileManger.createDirectory(at: itemFolderURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            if fileManger.fileNotExists(atPath: listFileURL.path) {
                itemListFile = ReaderItemList()
                if itemListFile == nil {
                    fatalError("File fail !")
                }
            }
            
            innerItemList = itemListFile
        } catch {
            print(error)
            return
        }
        
        asyncScan()
    }
    
    func asyncScan() {
        queue.async { self.scan() }
    }
    
    func syncScan() {
        queue.async { self.scan() }
    }
    
    func getReaderItemList() -> [ReaderItem] {
        var result: ReaderItemList?
        
        queue.sync { result = self.itemList }
        
        guard let result = result else {
            return []
        }
        return result.items
    }
    
    func getReaderItemFile(name: String, complete: ((ReaderItemFile?) -> Void)?) {
        queue.async {
            complete?(self.readReaderItemFile(name: name)?.1)
        }
    }
    
    func getReaderItemFile(name: String) -> ReaderItemFile? {
        var result: (ReaderItem, ReaderItemFile)?
        queue.sync { result = readReaderItemFile(name: name) }
        return result?.1
    }
    
    private func decoderTxtFormat(data: Data) -> String? {
        
        if let fileString = String(utf8Data: data) {
            return fileString
        }
        
        if let fileString = String(big5Data: data) {
            return fileString
        }
        
        if let fileString = String(big5_HKSCS_1999Data: data) {
            return fileString
        }
        
        if let fileString = String(GB_18030_2000Data: data) {
            return fileString
        }
        
        return nil
    }
    
    private func readReaderItemFile(name: String) -> (ReaderItem, ReaderItemFile)? {
        guard let item = self.itemList?.firstItem(of: name) else {
            return nil
        }

        if let file = readItemFile(item) {
            return (item, file)
        }
        
        let documentFileURL = documentURL.appendingPathComponent(item.name)
        guard let fileData = try? Data(contentsOf: documentFileURL) else {
            return nil
        }
       
        guard let fileString = decoderTxtFormat(data: fileData) else {
            return nil
        }
        
        var itemFile = ReaderItemFile()
        
        itemFile.rowText = fileString.split(omittingEmptySubsequences: false) {
            switch $0 {
            case Character("\n") :
                return true
            case Character("\r\n") :
                return true
            default :
                return false
            }
        }.map {
            String($0)
        }
        
        return (item, itemFile)
    }
}

extension ReaderManger {
    private func scan() {
        guard var fileItemList = self.itemList else {
            return
        }
        
        let fileItemNames = fileItemList.itemName()
        let scanItemNames = fileManger.documentItemURL(isFile: true).compactMap { $0.lastPathComponent }
        let addNames = Set(scanItemNames).subtracting(Set(fileItemNames)).sorted()
        let deleteNames = Set(fileItemNames).subtracting(Set(scanItemNames)).sorted()

        fileItemList.removalAll(name: deleteNames) { self.deleteItem($0) }
        fileItemList.appendAll(name: addNames) { self.saveItem($0) }
        
        self.itemList = fileItemList
    }

}

extension ReaderManger {
    private func readItemFile(_ item: ReaderItem) -> ReaderItemFile? {
        let itemFileURL = itemFolderURL.appendingPathComponent("cache_\(item.name)")
        
        var result: ReaderItemFile? = nil
        
        fileQueue.sync(flags: .barrier) {
            guard let data = try? Data(contentsOf: itemFileURL) else {
                result = nil
                return
            }
            result = try? JSONDecoder().decode(ReaderItemFile.self, from: data)
        }
        
        return result
    }
    
    func saveItem(_ item: ReaderItem) {
        let itemURL = itemFolderURL.appendingPathComponent(item.name)
        
        fileQueue.sync(flags: .barrier) {
            do {
                let data = try JSONEncoder().encode(item)
                try data.write(to: itemURL)
            } catch {
                print(error)
            }
        }
    }
    
    private func deleteItem(_ item: ReaderItem) {
        let itemURL = itemFolderURL.appendingPathComponent(item.name)
        
        fileQueue.sync(flags: .barrier) {
            do {
                try fileManger.removeItem(at: itemURL)
            } catch {
                print(error)
            }
        }
    }
}

extension ReaderManger {
    private var itemListFile: ReaderItemList? {
        set {
            fileQueue.sync(flags: .barrier) {
                guard let data = try? JSONEncoder().encode(newValue) else {
                    return
                }
                try? data.write(to: listFileURL)
            }
        }
        get {
            var result: ReaderItemList? = nil
            fileQueue.sync(flags: .barrier) {
                guard let data = try? Data(contentsOf: listFileURL) else {
                    result = nil
                    return
                }
                result = try? JSONDecoder().decode(ReaderItemList.self, from: data)
            }
            return result
        }
    }
}


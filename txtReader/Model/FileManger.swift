//
//  FileListManger.swift
//  txtReader
//
//  Created by peter on 2021/9/20.
//

import Foundation

class FileListManger {
    static let rootFolderName = "data"
    static let listFileName = "list.info"
    static let share = FileListManger.init(removallAll: false)!
    private let globalQueue = DispatchQueue.global()
    
    let fileManger = FileManager.default
    let documentDirectoryUrl: URL
    let rootFolderUrl: URL
    let fileListUrl: URL
    
    // Protect data
    private let innerFileListInformationQueue = DispatchQueue(label: "innerFileListInformationQueue", attributes: .concurrent)
    
    private var innerFileListInformation = FileListInformation()
    
    var fileListInformation: FileListInformation {
        get {
            var result = FileListInformation()
            innerFileListInformationQueue.sync {
                result = innerFileListInformation
            }
            return result
        }
        set {
            innerFileListInformationQueue.sync(flags: .barrier) {
                innerFileListInformation = newValue
                Self.saveFileListInformation(stroe: innerFileListInformation, to: fileListUrl)
            }
        }
    }
    
    init?(removallAll: Bool = false) {
        guard let url = fileManger.urls(for: .documentDirectory,
                                        in: .userDomainMask
        ).first else {
            return nil
        }
        documentDirectoryUrl = url

        // Get root folder path.
        rootFolderUrl = documentDirectoryUrl.appendingPathComponent(Self.rootFolderName, isDirectory: true)
        fileListUrl = rootFolderUrl.appendingPathComponent(Self.listFileName, isDirectory: false)
        
        do {
            if removallAll == true {
                try fileManger.removeItem(at: rootFolderUrl)
            }
            
            // If "data" folder doesn't exist, create it.
            if fileManger.fileExists(atPath: rootFolderUrl.path) != true {
                try fileManger.createDirectory(at: rootFolderUrl, withIntermediateDirectories: false, attributes: nil)
            }
            
            // If "list.info" doesn't exist, create it.
            if fileManger.fileExists(atPath: fileListUrl.path) != true {
                Self.saveFileListInformation(stroe: FileListInformation(), to: fileListUrl)
            }
        } catch {
            print(error)
            return nil
        }
        
        // Read file list information
        guard let fileList = Self.readFileListInformation(from: fileListUrl) else {
            return nil
        }
        innerFileListInformation = fileList
    }
    
    static func saveFileListInformation(stroe fileInfomation: FileListInformation, to path: URL) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(fileInfomation) else {
            return
        }
        try? data.write(to: path)
    }
    
    static func readFileListInformation(from path: URL) -> FileListInformation? {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: path) else {
            return nil
        }
        return try? decoder.decode(FileListInformation.self, from: data)
    }
    
    func scan(complete: @escaping (_ fileListInformation: FileListInformation) -> Void) {
        globalQueue.async {
            let fileList = self.fileListInformation
            let fileUrls = self.fileManger.documentItemURL(isFile: true)
            
            for fileUrl in fileUrls {
                print(fileUrl.lastPathComponent)
            }
            
            print("Total files is \(fileUrls.count)")
            
            complete(fileList)
        }
        globalQueue.resume()
    }
}

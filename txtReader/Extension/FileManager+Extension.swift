//
//  FileManager+Extension.swift
//  txtReader
//
//  Created by peter on 2021/9/20.
//

import Foundation
import UIKit

extension FileManager {
    func removeAll(baseURL: URL, name: [String]) {
        name.forEach {
            try? self.removeItem(at: baseURL.appendingPathComponent($0))
        }
    }
    
    var documentDirectoryURL: URL? {
        self.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func documentItemURL(_ url: URL? = nil, isFile: Bool) -> [URL] {
        var urlList: [URL] = []
        var baseURL: URL
        
        if url == nil {
            guard let documentDirectoryUrl = self.urls(for: .documentDirectory,
                                               in: .userDomainMask
            ).first else {
                return []
            }
            baseURL = documentDirectoryUrl
        } else {
            baseURL = url!
        }
        
        do {
            urlList = try self.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
            if isFile {
                urlList = urlList.filter {
                    if $0.hasDirectoryPath {
                       return false
                    }
                    if $0.pathExtension == "" {
                        return false
                    }

                    return true
                }
            }
        } catch {
            print(error)
        }
        
        return urlList
    }
    
    func fileNotExists(atPath path: String) -> Bool {
        !fileExists(atPath: path)
    }
}

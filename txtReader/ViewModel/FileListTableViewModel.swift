//
//  FileListTableViewModel.swift
//  txtReader
//
//  Created by peter on 2021/9/26.
//

import Foundation
import UIKit
import OpenCC

@objc protocol FileListTableViewModelDelegate: AnyObject {
    @objc optional func contentDidLoad(row at: Int, openBook: Bool)
}

class FileListTableViewModel {
    private let reader = ReaderManger.share
    weak var delegate: FileListTableViewModelDelegate?
    private var bookModel: [BookModel] = []
    private var systemSettingModel = SystemSettingModel()
    private static var firstLoading = true
    private let converter = try! ChineseConverter(options: [.traditionalize, .twStandard, .twIdiom])
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector:
                                                #selector(updateSystemSetting(noti:)),
                                               name: ReaderManger.systemSettingUpdateNotificationName,
                                               object: nil)
    }
    
    func loadContent() {
        updateSortByLastReadTime()
    }
    
    /**
     System setting changed event
     */
    @objc func updateSystemSetting(noti: Notification) {
        loadContent()
    }
    
    /**
     Get original book name which not display to user.
     */
    func getBookName(row: Int) -> String? {
        if row >= bookModel.count {
            return nil
        }
        
        return bookModel[row].name
    }
    
    /**
     Book file list, these information show on screen for user.
     */
    func row(row: Int) -> (name: String, percent: String, cover: String)? {
        if row >= bookModel.count {
            return nil
        }
        
        var name = bookModel[row].name
        if systemSettingModel.nameAutomaticChineseTraditional {
            name = converter.convert(name)
        }
        
        guard let totalRows = bookModel[row].totalRows,
              let lastReadTime = bookModel[row].lastReadTime else {
            return (name, "新增", name)
        }
        
        /* Auxiliary time text */
        var timeString = ""
        let time = lastReadTime.timeIntervalSinceNow
        switch time {
        case -900...0:
            timeString = "．剛剛"
        case -1800...0:
            timeString = "．30分鐘"
        case -3600...0:
            timeString = "．1小時"
        case (-86400 * 1)...0:
            timeString = "．1日"
        case (-86400 * 2)...0:
            timeString = "．2日"
        case (-86400 * 3)...0:
            timeString = "．3日"
        case (-86400 * 4)...0:
            timeString = "．4日"
        case (-86400 * 5)...0:
            timeString = "．5日"
        case (-86400 * 6)...0:
            timeString = "．6日"
        case (-86400 * 7)...0:
            timeString = "．一週"
        default:
            timeString = "．一週以上"
        }
        
        if totalRows == 0 {
            return (name, "0% \(timeString)", name)
        }
        
        if bookModel[row].readRow == 0 {
            return (name, "0% \(timeString)", name)
        }
        
        let percent = Double(bookModel[row].readRow * 100) / Double(totalRows)
        return (name, (String(format: "%.2f", percent) + "% \(timeString)"), name)
    }
    
    func rowCount() -> Int {
        bookModel.count
    }
}

extension FileListTableViewModel {
    private func updateSortByLastReadTime() {
        reader.getUserPutFiles { bookModel, systemSetting in
            self.systemSettingModel = systemSetting
            
            guard let bookModel = bookModel else {
                return
            }
            if bookModel.count <= 0 {
                return
            }
            
            self.bookModel = bookModel.sorted {
                if $0.lastReadTime == $1.lastReadTime {
                    return $0.name > $1.name
                }
                
                if $0.lastReadTime != nil, $1.lastReadTime == nil {
                        return true
                }
                
                if $0.lastReadTime == nil, $1.lastReadTime != nil {
                        return false
                }
                
                return $0.lastReadTime! > $1.lastReadTime!
            }
            
            var openBook = false
            if Self.firstLoading, systemSetting.openLastReadBook {
                openBook = true
            }
            Self.firstLoading = false
            
            self.delegate?.contentDidLoad?(row: 0, openBook: openBook)
        }
    }
}

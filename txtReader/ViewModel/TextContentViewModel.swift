//
//  TextContentViewModel.swift
//  txtReader
//
//  Created by peter on 2021/10/2.
//

import Foundation

import Foundation
import UIKit
import OpenCC

@objc protocol TextContentViewModelDelegate: AnyObject {
    @objc optional func update(offset row: Int, title: String)
    @objc optional func updateFormat(fontSize: Int, minimumLineHeight: Int)
    @objc optional func rowAt(row to: Int)
}

struct ContentMenuItem {
    var title: String
    var row: Int
    var percent: Double
}

class TextContentViewModel {
    private let reader = ReaderManger.share
    weak var delegate: TextContentViewModelDelegate?
    
    private let name: String
    private var bookModel: BookModel
    private var bookContentModel: BookContentModel
    private var systemSettingModel = SystemSettingModel()
    
    private var lastShowRow = 0
    
    private let converter = try! ChineseConverter(options: [.traditionalize, .twStandard, .twIdiom])
    
    init(name: String) {
        self.name = name
        self.bookContentModel = BookContentModel(name: name, content: [])
        self.bookModel = BookModel(name: name)
        
        NotificationCenter.default.addObserver(self,
                                               selector:
                                                #selector(updateSystemSetting(noti:)),
                                               name: ReaderManger.systemSettingUpdateNotificationName,
                                               object: nil)
    }
    
    @objc func updateSystemSetting(noti: Notification) {
        guard let userInfo = noti.userInfo else {
            return
        }
        
        guard let setting = userInfo[ReaderManger.systemSettingUserInfoKey] as? SystemSettingModel else {
            return
        }
        
        /* Update */
        self.systemSettingModel = setting
        
        let fontSize = setting.fontSize
        let minimumLineHeight = setting.fontSize + setting.lineSpace
        self.delegate?.updateFormat?(fontSize: fontSize, minimumLineHeight: minimumLineHeight)
    }
    
    func loadContent() {
        let setting = self.reader.getSystemSetting()
        let fontSize = setting.fontSize
        let minimumLineHeight = setting.fontSize + setting.lineSpace
        
        self.systemSettingModel = setting
        self.delegate?.updateFormat?(fontSize: fontSize, minimumLineHeight: minimumLineHeight)
        
        reader.getBookContent(name: name) { bookContentModel in
            guard let bookContentModel = bookContentModel else {
                return
            }
            
            (self.bookModel, self.bookContentModel) = bookContentModel
            self.delegate?.update?(offset: self.bookModel.readRow, title: self.bookModel.name)
        }
    }
    
    /**
     Row content
     */
    func row(row: Int) -> String? {
        if row >= bookContentModel.content.count {
            return nil
        }
        lastShowRow = row
        
        if systemSettingModel.contentAutomaticChineseTraditional {
            return converter.convert(bookContentModel.content[row])
        } else {
            return bookContentModel.content[row]
        }
    }
    
    /**
     Total rows
     */
    func rowCount() -> Int {
        bookContentModel.content.count
    }
    
    /**
     Save the read schedule by specified row.
     */
    func saveRowSchedule(row: Int) {
        bookModel.readRow = row
        bookModel.lastReadTime = Date()
        reader.updateBookModel(bookModel: bookModel)
    }
    
    /**
    Delegate which ask content row to specified row.
     */
    func scrollToRow(row: Int) {
        delegate?.rowAt?(row: row)
    }
    
    /**
     The index of reading chapter or paragraph.
     */
    func currentMenuIndex() -> Int {
        guard var index = (bookContentModel.chapter?.firstIndex {
            return $0 > lastShowRow
        }) else {
            return 0
        }
        
        if index > 0 {
            index -= 1
        }
        
        return index
    }
    
    /**
     The list of chapter or paragraph.
     */
    func menu() -> [ContentMenuItem] {
        var item: [ContentMenuItem] = []
        
        bookContentModel.chapter?.forEach {
            
            var title = ""
            if systemSettingModel.contentAutomaticChineseTraditional {
                title = converter.convert(bookContentModel.content[$0])
            } else {
                title = bookContentModel.content[$0]
            }
            
            let percent = Double($0) / Double(bookContentModel.content.count)
            item.append(ContentMenuItem(title: title, row: $0, percent: percent))
        }
        
        return item
    }
}

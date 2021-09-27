//
//  TextTableViewModel.swift
//  txtReader
//
//  Created by peter on 2021/9/26.
//

import Foundation

@objc protocol TextTableViewModelDelegate {
    @objc optional func update(offset row: Int, title: String)
}

class TextTableViewModel {
    private let reader = ReaderManger.share
    var delegate: TextTableViewModelDelegate?
    
    private let name: String
    private var bookModel: BookModel
    private var bookContentModel: BookContentModel
    
    init(name: String) {
        self.name = name
        self.bookContentModel = BookContentModel(name: name, content: [])
        self.bookModel = BookModel(name: name)
    }
    
    func loadContent() {
        reader.getBookContent(name: name) { bookContentModel in
            guard let bookContentModel = bookContentModel else {
                return
            }
            
            (self.bookModel, self.bookContentModel) = bookContentModel
            self.delegate?.update?(offset: self.bookModel.readRow, title: self.bookModel.name)
        }
    }
    
    func row(row: Int) -> String? {
        if row >= bookContentModel.content.count {
            return nil
        }
        
        return String.chineseTraditional(bookContentModel.content[row])
    }
    
    func percent(row: Int) -> String {
        guard let totalRow = bookModel.totalRows else {
            return "已讀 0%"
        }
        
        let percent = Double(row * 100) / Double(totalRow)
        return String(format: "已讀 %.2f", percent) + "%"
    }
    
    func rowCount() -> Int {
        bookContentModel.content.count
    }
    
    func saveRow(row: Int) {
        bookModel.readRow = row
        bookModel.lastReadTime = Date()
        reader.updateBookModel(bookModel: bookModel)
    }
}

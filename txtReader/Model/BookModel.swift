//
//  BookModel.swift
//  txtReader
//
//  Created by peter on 2021/9/26.
//

import Foundation

struct BookModel: Codable {
    var name: String
    var totalRows: Int? = nil
    var readRow: Int = 0
    var lastReadTime: Date? = nil
    var addBookTime: Date = Date()
}

struct BookContentModel: Codable {
    var name: String
    var content: [String] = []
    var chapter: [Int]?
}

//
//  File.swift
//  txtReader
//
//  Created by peter on 2021/9/26.
//

import Foundation

struct SystemSettingModel: Codable {
    var contentAutomaticChineseTraditional: Bool = true
    var nameAutomaticChineseTraditional: Bool = true
    var openLastReadBook: Bool = false
    var fontSize: Int = 20
    var lineSpace: Int = 20
}

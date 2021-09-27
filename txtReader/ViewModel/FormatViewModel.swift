//
//  FormatViewModel.swift
//  txtReader
//
//  Created by peter on 2021/10/2.
//

import Foundation

class FormatViewModel {
    private let reader = ReaderManger.share
    
    init() {
        
    }
    
    func increaseFontSize(size: Int) {
        var setting = reader.getSystemSetting()
        setting.fontSize += size
        reader.updateSystemSetting(systemSetting: setting)
    }
    
    func reduceFontSize(size: Int) {
        var setting = reader.getSystemSetting()
        if setting.fontSize > size {
            setting.fontSize -= size
        } else {
            setting.fontSize = 0
        }
        reader.updateSystemSetting(systemSetting: setting)
    }
    
    func increaseLineSpace(value: Int) {
        var setting = reader.getSystemSetting()
        setting.lineSpace += value
        reader.updateSystemSetting(systemSetting: setting)
    }
    
    func reduceLineSpace(value: Int) {
        var setting = reader.getSystemSetting()
        if setting.lineSpace > value {
            setting.lineSpace -= value
        } else {
            setting.lineSpace = 0
        }
        reader.updateSystemSetting(systemSetting: setting)
    }
}

//
//  SettingTableViewModel.swift
//  txtReader
//
//  Created by peter on 2021/10/10.
//

import Foundation

class SettingTableViewModel {
    private let reader = ReaderManger.share
    var systemSettingModel: SystemSettingModel
    
    init() {
        systemSettingModel = reader.getSystemSetting()
    }
    
    func contentAutomaticChineseTraditional() -> Bool {
        return systemSettingModel.contentAutomaticChineseTraditional
    }
    
    func setContentAutomaticChineseTraditional(enable: Bool) {
        systemSettingModel.contentAutomaticChineseTraditional = enable
        reader.updateSystemSetting(systemSetting: systemSettingModel)
    }
    
    func openLastReadBook() -> Bool {
        return systemSettingModel.openLastReadBook
    }
    
    func setOpenLastReadBook(enable: Bool) {
        systemSettingModel.openLastReadBook = enable
        reader.updateSystemSetting(systemSetting: systemSettingModel)
    }
    
    func nameAutomaticChineseTraditional() -> Bool {
        return systemSettingModel.nameAutomaticChineseTraditional
    }
    
    func setNameAutomaticChineseTraditional(enable: Bool) {
        systemSettingModel.nameAutomaticChineseTraditional = enable
        reader.updateSystemSetting(systemSetting: systemSettingModel)
    }
}

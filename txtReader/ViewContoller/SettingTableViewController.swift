//
//  SettingTableViewController.swift
//  txtReader
//
//  Created by peter on 2021/10/10.
//

import UIKit

class SettingTableViewController: UITableViewController {
    @IBOutlet weak var startLastReadBookSwitch: UISwitch!
    @IBOutlet weak var contentTraditionalConversionSwitch: UISwitch!
    @IBOutlet weak var nameTraditionalConversionSwitch: UISwitch!
    let settingTableViewModel = SettingTableViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startLastReadBookSwitch.isOn = settingTableViewModel.openLastReadBook()
        nameTraditionalConversionSwitch.isOn = settingTableViewModel.nameAutomaticChineseTraditional()
        contentTraditionalConversionSwitch.isOn = settingTableViewModel.contentAutomaticChineseTraditional()
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = (view as? UITableViewHeaderFooterView) else {
            return
        }
        
        var content = header.defaultContentConfiguration()
        
        var sectionHeaderText = ""
        switch section {
        case 0:
            sectionHeaderText = "一般"
        case 1:
            sectionHeaderText = "閱讀"
        default:
            sectionHeaderText = "Error"
        }
        
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20),
                          NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        
        content.attributedText = NSAttributedString(string: sectionHeaderText, attributes: attributes)
        header.contentConfiguration = content
    }
    
    @IBAction func contentTraditionalConversionChanged(_ sender: UISwitch) {
        settingTableViewModel.setContentAutomaticChineseTraditional(enable: sender.isOn)
    }
    
    @IBAction func nameTraditionalConversionChanged(_ sender: UISwitch) {
        settingTableViewModel.setNameAutomaticChineseTraditional(enable: sender.isOn)
    }
    
    @IBAction func openLastReadBookChanged(_ sender: UISwitch) {
        settingTableViewModel.setOpenLastReadBook(enable: sender.isOn)
    }
}

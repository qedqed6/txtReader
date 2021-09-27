//
//  FormatViewController.swift
//  txtReader
//
//  Created by peter on 2021/10/2.
//

import UIKit

class FormatViewController: UIViewController {
    let formatViewModel = FormatViewModel()
    @IBOutlet weak var brightnessSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        brightnessSlider.value = Float(UIScreen.main.brightness)
    }
    
    @IBAction func smallFontSize(_ sender: Any) {
        formatViewModel.reduceFontSize(size: 1)
    }
    
    @IBAction func largeFontSize(_ sender: Any) {
        formatViewModel.increaseFontSize(size: 1)
    }
    
    @IBAction func samllLineSpace(_ sender: Any) {
        formatViewModel.reduceLineSpace(value: 1)
    }
    
    @IBAction func largeLineSpace(_ sender: Any) {
        formatViewModel.increaseLineSpace(value: 1)
    }
    
    @IBAction func brightness(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
    }
}

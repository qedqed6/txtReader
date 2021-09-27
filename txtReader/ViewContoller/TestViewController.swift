//
//  TestViewController.swift
//  txtReader
//
//  Created by peter on 2021/10/3.
//

import UIKit

class TestViewController: UIViewController {

    let greenView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .clear
        
        view.addSubview(greenView)
        greenView.backgroundColor = .green
        greenView.translatesAutoresizingMaskIntoConstraints = false
        //greenView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //greenView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        print("\(Self.self), \(#function)")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  TextContentMenuViewController.swift
//  txtReader
//
//  Created by peter on 2021/10/3.
//

import UIKit

class TextContentMenuViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuImageView: UIImageView!
    
    let textContentViewModel: TextContentViewModel
    var menu: [ContentMenuItem] = []
    var currentMenuIndex = 0

    init?(coder: NSCoder, textContentViewModel: TextContentViewModel) {
        self.textContentViewModel = textContentViewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        menu = textContentViewModel.menu()
        if menu.count > 0 {
            currentMenuIndex = textContentViewModel.currentMenuIndex()
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: currentMenuIndex, section: 0), at: .middle, animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        tableView.layer.cornerRadius = 10
        menuImageView.layer.cornerRadius = 10
    }
    
    @IBAction func tap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension TextContentMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = menu[indexPath.row].row
        textContentViewModel.scrollToRow(row: row)
        dismiss(animated: true, completion: nil)
    }
}

extension TextContentMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TextContentMenuTableViewCell.self)", for: indexPath) as? TextContentMenuTableViewCell else {
            return UITableViewCell()
        }

        cell.textLabel?.text = menu[indexPath.row].title
        cell.textLabel?.textColor = .darkGray
        if indexPath.row == currentMenuIndex {
            cell.backgroundColor = .lightGray
        } else {
            cell.backgroundColor = .white
        }
        
        return cell
    }
}

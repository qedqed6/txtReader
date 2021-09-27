//
//  TextViewController.swift
//  txtReader
//
//  Created by peter on 2021/10/1.
//

import UIKit

class TextViewController: UIViewController {
    @IBOutlet weak var textTableView: UITableView!
    let name: String
    let textTableViewModel: TextTableViewModel
    
    init?(coder: NSCoder, name: String) {
        self.name = name
        self.textTableViewModel = TextTableViewModel(name: name)
        super.init(coder: coder)
        self.textTableViewModel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textTableView.delegate = self
        textTableView.dataSource = self
    }
}

extension TextViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TextTableViewCell.self)", for: indexPath) as? TextTableViewCell else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = "\(indexPath.row)"
        
        return cell
    }
    
    
}

extension TextViewController: UITableViewDelegate {
    
}

extension TextViewController: TextTableViewModelDelegate {
    func update(offset row: Int, title: String) {
        DispatchQueue.main.async {
            self.navigationItem.prompt = title
            self.textTableView.reloadData()
            self.textTableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: false)
        }
    }
}

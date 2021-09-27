//
//  TextTableViewController.swift
//  txtReader
//
//  Created by peter on 2021/9/20.
//

import UIKit

class TextTableViewController: UITableViewController {
    let name: String
    let textTableViewModel: TextTableViewModel
    
    @IBOutlet weak var leftBarButtonItem: UIBarButtonItem!
    
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
        tableView.separatorStyle = .none
        navigationController?.setNavigationBarHidden(true, animated: true)
        textTableViewModel.loadContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.hidesBarsOnTap = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard let index = self.tableView.indexPathsForVisibleRows else {
            return
        }
        var row = 0
        if index.count != 0 {
            row = index[0].row
        }

        textTableViewModel.saveRow(row: row)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textTableViewModel.rowCount()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TextTableViewCell.self)", for: indexPath) as? TextTableViewCell else {
            return UITableViewCell()
        }
        
        guard let row = textTableViewModel.row(row: indexPath.row) else {
            return UITableViewCell()
        }
        
        cell.textView.font = UIFont.systemFont(ofSize: 20)
        cell.textView.text = row
        cell.textView.textContainerInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        
        return cell
    }
}

extension TextTableViewController: TextTableViewModelDelegate {
    func update(offset row: Int, title: String) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: false)
        }
    }
}

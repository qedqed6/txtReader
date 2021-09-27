//
//  TextContentViewController.swift
//  txtReader
//
//  Created by peter on 2021/10/2.
//

import UIKit

class TextContentViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var formatBarButton: UIBarButtonItem!
    
    let slider: UISlider
    let indicator: UIActivityIndicatorView
    
    let name: String
    let textContentViewModel: TextContentViewModel
    var fontSize: CGFloat = 20
    var minimumLineHeight: CGFloat = 20
    
    init?(coder: NSCoder, name: String) {
        self.name = name
        self.textContentViewModel = TextContentViewModel(name: name)
        self.slider = UISlider()
        self.indicator = UIActivityIndicatorView()
        super.init(coder: coder)
        
        self.textContentViewModel.delegate = self
        self.slider.addTarget(self, action: #selector(scroll), for: .valueChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* TableView */
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorStyle = .none
                
        /* Slider View */
        view.addSubview(slider)
        slider.transform = CGAffineTransform.identity.rotated(by: CGFloat(Double.pi/2))
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, constant: -50).isActive = true
        slider.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        slider.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        let image = UIImage(systemName: "circlebadge.fill")
        image?.withTintColor(.systemGray)
        slider.setThumbImage(image, for: .normal)
        slider.tintColor = .systemGray
        
        /* Activity Indicator View */
        indicator.hidesWhenStopped = true
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        /* Hidden bars */
        navigationController?.setNavigationBarHidden(true, animated: false)
        slider.isHidden = true
        
        /* */
        indicator.startAnimating()
        
        /* Load text context */
        textContentViewModel.loadContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

        textContentViewModel.saveRowSchedule(row: row)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func tap(_ sender: Any) {
        guard let navigationController = navigationController else {
            return
        }
        
        var hidden = navigationController.isNavigationBarHidden
        hidden.toggle()
        navigationController.setNavigationBarHidden(hidden, animated: true)
        slider.isHidden = hidden
    }
    
    @objc func scroll(_ sender: UISlider) {
        let total = Float(textContentViewModel.rowCount())
        var scrollTo = Int(total * sender.value)
        if scrollTo == Int(total) {
           scrollTo = scrollTo - 1
        }
        
        self.tableView.scrollToRow(at: IndexPath(row: scrollTo, section: 0), at: .top, animated: false)
    }
    
    @IBSegueAction func showMenu(_ coder: NSCoder) -> TextContentMenuViewController? {
        let controller = TextContentMenuViewController(coder: coder, textContentViewModel: textContentViewModel)
        navigationController?.setNavigationBarHidden(true, animated: true)
        slider.isHidden = true
        return controller
    }
}

extension TextContentViewController: UIPopoverPresentationControllerDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (sender as? UIBarButtonItem) === formatBarButton {
            segue.destination.preferredContentSize = CGSize(width: 300, height: 132)
            segue.destination.popoverPresentationController?.delegate = self
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
       return .none
    }
}

extension TextContentViewController: UITableViewDelegate {
    
}

extension TextContentViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textContentViewModel.rowCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TextContentTableViewCell.self)", for: indexPath) as? TextContentTableViewCell else {
            return UITableViewCell()
        }
        
        guard let row = textContentViewModel.row(row: indexPath.row) else {
            return UITableViewCell()
        }
        
        /* slider */
        slider.value = Float(indexPath.row) / Float(textContentViewModel.rowCount())
        
        /* cell */
        cell.isEditing = false
        cell.isSelected = false
        
        cell.textView.isEditable = false
        cell.textView.isSelectable = false
        cell.textView.isScrollEnabled = false
        cell.textView.textContainerInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        
        /* text attribute */
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = self.minimumLineHeight
        
        let font = UIFont.systemFont(ofSize: self.fontSize)

        let attributes = [NSAttributedString.Key.paragraphStyle: style,
                          NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: UIColor.label]
        
        cell.textView.attributedText = NSAttributedString(string: row, attributes: attributes)
        
        return cell
    }
}

extension TextContentViewController: TextContentViewModelDelegate {
    func update(offset row: Int, title: String) {
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: false)
        }
    }
    
    func updateFormat(fontSize: Int, minimumLineHeight: Int) {
        DispatchQueue.main.async {
            self.fontSize = CGFloat(fontSize)
            self.minimumLineHeight = CGFloat(minimumLineHeight)
            self.tableView.reloadData()
        }
    }
    
    func rowAt(row to: Int) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: to, section: 0), at: .top, animated: false)
        }
    }
}

//
//  FileListTableViewController.swift
//  txtReader
//
//  Created by peter on 2021/9/20.
//

import UIKit

class FileListTableViewController: UITableViewController {
    let fileListTableViewModel = FileListTableViewModel()
    var snapshotView: UIView? = nil
    var bookAnimation = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fileListTableViewModel.delegate = self
        self.navigationController?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let navigationController = navigationController else {
            return
        }
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.hidesBarsOnTap = false
        navigationController.navigationBar.prefersLargeTitles = true
        navigationItem.title = "書庫"
        
        /* load content */
        fileListTableViewModel.loadContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    @IBAction func unwindToFileListTableView(_ unwindSegue: UIStoryboardSegue) {
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileListTableViewModel.rowCount()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(FileListTableViewCell.self)", for: indexPath) as? FileListTableViewCell else {
            return UITableViewCell()
        }
        
        guard let row = fileListTableViewModel.row(row: indexPath.row) else {
            return UITableViewCell()
        }
        
        cell.accessoryType = .none
        
        /* Book cover */
        let cover = cover(title: row.cover, frame: cell.cover.frame, fontSize: 8)
        cell.cover.image = imageFromLayer(layer: cover)
        
        /* Book title */
        let nameAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
                          NSAttributedString.Key.foregroundColor: UIColor.label]
        
        cell.name.numberOfLines = 0
        cell.name.attributedText = NSAttributedString(string: row.name, attributes: nameAttributes)
        
        /* Book schedule */
        let percentAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                                 NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        cell.percent.numberOfLines = 0
        cell.percent.attributedText = NSAttributedString(string: row.percent, attributes: percentAttributes)
        
        return cell
    }
    
    @IBSegueAction func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        bookAnimation = false
        return SettingTableViewController(coder: coder)
    }
    
    @IBSegueAction func showTextContent(_ coder: NSCoder) -> TextContentViewController? {
        guard let indexPath = self.tableView.indexPathForSelectedRow else {
            return nil
        }
        
        guard let cell = (tableView.cellForRow(at: indexPath) as? FileListTableViewCell) else {
            return nil
        }
        
        var coverPosition = cell.cover.convert(CGPoint.zero, to: self.tableView)
        coverPosition.y -= tableView.contentOffset.y
        
        let snapshotViewframe = CGRect(origin: coverPosition, size: cell.cover.frame.size)
        snapshotView = UIView(frame: snapshotViewframe)
        
        let coverFrame = CGRect(origin: CGPoint.zero, size: cell.cover.frame.size)
        snapshotView?.layer.addSublayer(cover(title: cell.name.text!, frame: coverFrame, fontSize: 8))
        
        guard let bookName = fileListTableViewModel.getBookName(row: indexPath.row) else {
            return nil
        }
        
        bookAnimation = true
        return TextContentViewController(coder: coder, name: bookName)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = (segue.destination as? TextContentViewController) else {
            return
        }

        destinationVC.transitioningDelegate = self
    }
}

extension FileListTableViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fromVC = fromVC as? FileListTableViewController else {
            return nil
        }
        
        switch operation {
        case .push:
            return fromVC.bookAnimation ? self : nil
        case .pop:
            return nil
        default:
            return nil
        }
    }
}

extension FileListTableViewController: FileListTableViewModelDelegate {
    func contentDidLoad(row at: Int, openBook: Bool) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: at, section: 0), at: .top, animated: false)
            
            if openBook {
                self.tableView.selectRow(at: IndexPath(row: at, section: 0), animated: false, scrollPosition: .top)
                self.performSegue(withIdentifier: "showContentSegue",
                sender: nil)
            }
        }
    }
}

extension FileListTableViewController: UIViewControllerTransitioningDelegate {
//  func animationController(forPresented presented: UIViewController,
//                           presenting: UIViewController,
//                           source: UIViewController)
//    -> UIViewControllerAnimatedTransitioning? {
//    return PushAnimator(snapshotView)
//  }
}

extension FileListTableViewController: UIViewControllerAnimatedTransitioning {

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1.8
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? FileListTableViewController,
          let toVC = transitionContext.viewController(forKey: .to)
          else {
            return
        }
        
        guard let sanpshotView = fromVC.snapshotView else {
            return
        }

        /* */
        let viewFrame = fromVC.view.frame.insetBy(dx: 30, dy: 30)
        var multiple = CGFloat.zero
        if viewFrame.height > viewFrame.width {
            multiple = viewFrame.width / sanpshotView.frame.width
        } else {
            multiple = viewFrame.height / sanpshotView.frame.height
        }
        
        let containerView = transitionContext.containerView
        //let finalFrame = transitionContext.finalFrame(for: toVC)

        let backgroudView = UIView(frame: fromVC.view.frame)
        backgroudView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)

        containerView.addSubview(toVC.view)
        containerView.addSubview(backgroudView)
        containerView.addSubview(sanpshotView)
        toVC.view.isHidden = true
        
        let duration = transitionDuration(using: transitionContext)
        
        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: .calculationModeLinear,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 10/100) {
                    sanpshotView.center = self.view.center
                    sanpshotView.layer.transform = CATransform3DMakeScale(multiple, multiple, 1)
                    backgroudView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 98/100, relativeDuration: 2/100) {
                    sanpshotView.center = self.view.center
                    sanpshotView.layer.magnificationFilter = .linear
                    sanpshotView.layer.transform = CATransform3DMakeScale(50, 50, 1)
                }
            },

            completion: { _ in
                backgroudView.removeFromSuperview()
                sanpshotView.removeFromSuperview()
                toVC.view.isHidden = false
                fromVC.view.layer.transform = CATransform3DIdentity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

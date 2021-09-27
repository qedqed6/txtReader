//
//  UIView+Snapshot.swift
//  txtReader
//
//  Created by peter on 2021/10/3.
//

import Foundation
import UIKit

extension UIView {
    func snapshot() -> UIImage? {
        guard (self.bounds.size.height > 0) && (self.bounds.size.width > 0) else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, UIScreen.main.scale)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func customSnapShotFrom() -> UIView {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let cellImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let imageView = UIImageView(image: cellImage)
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = 0.0
        imageView.layer.shadowOffset = CGSize(width: 2, height: 2)
        imageView.layer.shadowRadius = 4.0
        imageView.layer.shadowOpacity = 1.0
        return imageView
    }
}

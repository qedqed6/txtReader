//
//  Draw.swift
//  txtReader
//
//  Created by peter on 2021/10/10.
//
import UIKit

func imageFromLayer(layer: CALayer) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, layer.isOpaque, 0)
    layer.render(in: UIGraphicsGetCurrentContext()!)
    
    let outputImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return outputImage!
}

let redGradientArray = [
    CGColor(red: 0.5, green: 0, blue: 0, alpha: 1),
    CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
]

let greenGradientArray = [
    CGColor(red: 0, green: 0.5, blue: 0, alpha: 1),
    CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
]

let blueGradientArray = [
    CGColor(red: 0.0, green: 0, blue: 0.5, alpha: 1),
    CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
]

let grayGradientArray = [
    CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
    CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
]

func cover(title: String, frame: CGRect, fontSize: CGFloat) -> CALayer {
    let layer = CALayer()
    let inset = CGFloat(2)
    layer.frame = frame
    
    /* Background color */
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = frame
    
    var color = 0
    
    title.forEach {
        guard let value = ($0.unicodeScalars.first?.value) else {
            return
        }
        color += Int(value / 4)
    }
    color = color % 4
    
    switch color {
    case 1:
        gradientLayer.colors = redGradientArray
    case 2:
        gradientLayer.colors = greenGradientArray
    case 3:
        gradientLayer.colors = blueGradientArray
    default:
        gradientLayer.colors = grayGradientArray
    }
    
    layer.addSublayer(gradientLayer)
    
    /* inner frame */
    let innerPath = UIBezierPath(rect: frame.insetBy(dx: inset, dy: inset))
    let innerShape = CAShapeLayer()
    innerShape.path = innerPath.cgPath
    innerShape.lineWidth = 0.2
    innerShape.fillColor = UIColor.clear.cgColor
    innerShape.strokeColor = UIColor.white.cgColor
    innerShape.frame = frame
    layer.addSublayer(innerShape)
    
    /* Title */
    let textLayer = CATextLayer()
    textLayer.frame = frame.insetBy(dx: inset, dy: inset)
    textLayer.contentsScale = 20
    textLayer.fontSize = fontSize
    textLayer.foregroundColor = UIColor.white.cgColor
    textLayer.alignmentMode = .center
    textLayer.isWrapped = true
    textLayer.string = title
    layer.addSublayer(textLayer)
    
    return layer
}

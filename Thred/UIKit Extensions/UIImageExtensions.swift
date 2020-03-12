//
//  UIImageExtensions.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func crop() -> UIImage? {
        var imageHeight = self.size.height
        var imageWidth = self.size.width
        if imageHeight > imageWidth {
            imageHeight = imageWidth
        }
        else {
            imageWidth = imageHeight
        }
        let size = CGSize(width: imageWidth, height: imageHeight)
        let refWidth : CGFloat = CGFloat(self.cgImage!.width)
        let refHeight : CGFloat = CGFloat(self.cgImage!.height)
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
        if let imageRef = self.cgImage!.cropping(to: cropRect) {
            let cropped = UIImage.init(cgImage: imageRef, scale: 0, orientation: self.imageOrientation)
            return cropped
        }
        return nil
    }
    
    func circleImage(_ cornerRadius: CGFloat, size: CGSize, color: UIColor, width: CGFloat) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            var path: UIBezierPath
            if size.height == size.width {
                if cornerRadius == size.width / 2 {
                    path = UIBezierPath(arcCenter: CGPoint(x: size.width/2, y: size.height/2), radius: cornerRadius, startAngle: 0, endAngle: 2.0*CGFloat(Double.pi), clockwise: true)
                }else {
                    path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                }
            }else {
                path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            }
            context.addPath(path.cgPath)
            context.clip()
            self.draw(in: rect)
            guard let uncompressedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                return nil
            }
            UIGraphicsEndImageContext()
            let imageView = UIImageView(frame: CGRect(origin: .zero, size: uncompressedImage.size))
            imageView.contentMode = .center
            imageView.image = uncompressedImage
            imageView.layer.cornerRadius = uncompressedImage.size.width / cornerRadius
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = width
            imageView.layer.borderColor = color.cgColor
            
            UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0)
            defer { UIGraphicsEndImageContext() }
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            imageView.layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }else {
            return nil
        }
    }
    
    
    func mainColor() -> UIColor{
        return UIColor(hue: 0.5861, saturation: 0.6, brightness: 1, alpha: 1.0) /* #66afff */
    }
}

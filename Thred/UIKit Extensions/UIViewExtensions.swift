//
//  UIViewExtensions.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    func hollowedCenter(offset: CGFloat) -> CAShapeLayer{
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: self.frame.midX, y: self.frame.midY),
                    radius: (self.frame.width / 2) - offset - 5,
                    startAngle: 0.0,
                    endAngle: 2.0 * .pi,
                    clockwise: false)
        path.addRect(CGRect(origin: .zero, size: self.frame.size))
        
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        return maskLayer
    }
    
    func roundCorners(_ corners: CACornerMask, radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        self.layer.maskedCorners = corners
        self.layer.cornerRadius = radius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        
    }
    
    func currentFirstResponder() -> UIResponder? {
        if self.isFirstResponder {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder() {
                return responder
            }
        }
        return nil
    }
    
    
    func showNoWifiLabel(){
        let n = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 40))
        n.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        n.text = "No Internet Connection"
        n.textColor = UIColor.white
        n.translatesAutoresizingMaskIntoConstraints = false
        n.textAlignment = .center
        self.addSubview(n)
        let guide = self.safeAreaLayoutGuide
        n.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 10).isActive = true
        n.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: -10).isActive = true
        n.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        n.heightAnchor.constraint(equalToConstant: 40).isActive = true
        n.transform = CGAffineTransform(translationX: self.frame.minX, y: self.frame.minY - n.frame.height * 2)
        UIView.animate(withDuration: 0.40, animations: {
            n.transform = CGAffineTransform(translationX: self.frame.minX, y: self.frame.minY)
        }, completion: { (finished: Bool) in
            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.removeWifiLabel(sender:)), userInfo: n, repeats: false)
        })
    }
    
    class noWifiLabel: UILabel{
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func layoutSubviews() {
            
        }
        
    }
        
    @objc func removeWifiLabel(sender: Timer){
        let n = sender.userInfo as? UILabel
        sender.invalidate()
        UIView.animate(withDuration: 0.15, animations: {
            n!.transform = CGAffineTransform(translationX: self.frame.minX, y: self.frame.minY - (n?.frame.height)! * 2)
        }, completion: { (finished: Bool) in
            n?.removeFromSuperview()
        })
    }
   
    func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
           let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
           let mask = CAShapeLayer()
           mask.path = path.cgPath
           self.layer.mask = mask
           self.clipsToBounds = true
    }
    
    func setRadiusWithShadow(_ radius: CGFloat? = nil) {
           //self.layer.cornerRadius = radius ?? self.frame.width / 2
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: -1, height: 2)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.7
    }
    
    func setRadiusWithShadowHeavy(_ radius: CGFloat? = nil) {
           //self.layer.cornerRadius = radius ?? self.frame.width / 2
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: -2.5, height: 5)
        self.layer.shadowRadius = 5.0
        self.layer.shadowOpacity = 0.7
    }
    
    func setRadiusWithShadowDesign(_ radius: CGFloat? = nil) {
           //self.layer.cornerRadius = radius ?? self.frame.width / 2
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: -2, height: 2)
        self.layer.shadowRadius = 1.0
        self.layer.shadowOpacity = 1.0
    }
    
    func removeShadow() {
        self.layer.shadowOffset = CGSize(width: 0 , height: 0)
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.cornerRadius = 0.0
        self.layer.shadowRadius = 0.0
        self.layer.shadowOpacity = 0.0
    }
    
    var hasShadow: Bool{
        return layer.shadowOpacity != 0.0 && layer.shadowRadius != 0.0
    }
}

//
//  SkeletonView.swift
//  SkeletonViewExample
//
//  Created by Roni Leshes on 3/16/18.
//  Copyright © 2018 Roni Leshes. All rights reserved.
//

import UIKit
import ColorCompatibility


class SkeletonView: UIView {
    
    let startLocations : [NSNumber] = [-1.0,-0.5, 0.0]
    let endLocations : [NSNumber] = [1.0,1.5, 2.0]
    
    let gradientBackgroundColor : UIColor = ColorCompatibility.quaternarySystemFill
    let gradientMovingColor : UIColor = ColorCompatibility.systemFill
        
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        gradientLayer.colors?[0] = gradientBackgroundColor.cgColor
        gradientLayer.colors?[1] = gradientMovingColor.cgColor
        gradientLayer.colors?[2] = gradientBackgroundColor.cgColor

        
    }
        
        //UIColor(named: "loadingColor")?.cgColor ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1).cgColor
    
    let movingAnimationDuration : CFTimeInterval = 0.8
    let delayBetweenAnimationLoops : CFTimeInterval = 0.8
    

     lazy var gradientLayer : CAGradientLayer = {
           
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [
            gradientBackgroundColor.cgColor,
            gradientMovingColor.cgColor,
            gradientBackgroundColor.cgColor
        ]
        gradientLayer.locations = self.startLocations
        self.layer.addSublayer(gradientLayer)
        return gradientLayer
    }()
    
    func addLayers(){
        if let layers = self.layer.sublayers{
            if !layers.contains(gradientLayer){
                self.layer.addSublayer(gradientLayer)
            }
        }
    }
   
    func startAnimating(){
                    
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = self.startLocations
        animation.toValue = self.endLocations
        animation.duration = self.movingAnimationDuration
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = self.movingAnimationDuration + self.delayBetweenAnimationLoops
        animationGroup.animations = [animation]
        animationGroup.repeatCount = .infinity
        
        self.gradientLayer.add(animationGroup, forKey: animation.keyPath)
    }
    
    func stopAnimating() {
        self.gradientLayer.removeAllAnimations()
        self.gradientLayer.removeFromSuperlayer()
    }
    
}

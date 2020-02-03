//
//  MainTabBarViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-01-13.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import AudioToolbox
import ColorCompatibility


class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.isTranslucent = false
        // Do any additional setup after loading the view.
    }
    
    @IBAction func unwindToTabBar(segue:  UIStoryboardSegue) {
        
        
    }
    
    let notificationCenter = NotificationCenter.default

    lazy var button: UIButton = {
        let tabHeight = self.tabBar.frame.size.height
        let width = (self.view.frame.width / 3) - 45
        let height = width
        let x = (self.view.frame.width / 3) + 22.5
        let y = self.view.frame.maxY - tabHeight - (height / 2)
        
        let button = UIButton.init(frame: CGRect(x: x, y: y, width: width, height: height))
        button.backgroundColor = ColorCompatibility.systemBackground
            //UIColor.init(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)
        button.tintColor = UIColor.gray
        button.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor 
        button.layer.borderWidth = 6.5
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(segueToCreationScreen(_:)), for: .touchUpInside)
        button.setRadiusWithShadow()
        return button
    }()
    
    @objc func segueToCreationScreen(_ sender: UIButton){
        AudioServicesPlaySystemSound(1520) // Actuate `Pop` feedback (strong boom)
        self.performSegue(withIdentifier: "new", sender: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

    }
    
    
       
    
    func animatePhotoBtn(){
       
        let colorAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderColor))
        colorAnimation.fromValue = UIColor.cyan
        colorAnimation.toValue = UIColor.blue
        let widthAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderWidth))
        widthAnimation.fromValue = 11.25
        widthAnimation.toValue = 12
        let bothAnimations = CAAnimationGroup()
        bothAnimations.duration = 1
        bothAnimations.animations = [colorAnimation, widthAnimation]
        bothAnimations.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        bothAnimations.repeatCount = .infinity
        bothAnimations.autoreverses = true
        button.layer.add(bothAnimations, forKey: "color/width")
    }
    
    override func viewDidLayoutSubviews() {
        self.view.insertSubview(button, aboveSubview: tabBar)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

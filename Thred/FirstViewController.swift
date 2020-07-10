//
//  FirstViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-01.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class FirstViewController: UIViewController {
    
    @IBOutlet weak var signInBtn: UIButton!
    
    @IBOutlet weak var thredLogoView: UIImageView!
    @IBOutlet weak var thredBackgroundView: UIView!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var signUpBtn: UIButton!
    
    var textToSet: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        signInBtn.layer.cornerRadius = signInBtn.frame.height / 2
        signInBtn.clipsToBounds = true
        
        signInBtn.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
        signInBtn.layer.borderWidth = 2
        
        signUpBtn.layer.cornerRadius = signUpBtn.frame.height / 2
        signUpBtn.clipsToBounds = true
        
        signUpBtn.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
        signUpBtn.layer.borderWidth = 2
        
        if textToSet == nil{
            textView.text = "Sign up to buy and design threds."
            textView.textColor = .secondaryLabel
        }
        else{
            textView.text = textToSet
            textView.textColor = .systemRed
        }
    }
    
    override func viewDidLayoutSubviews() {
        thredBackgroundView.layer.cornerRadius = thredBackgroundView.frame.height / 2
        thredBackgroundView.clipsToBounds = true
        thredBackgroundView.layer.borderColor = UIColor.systemBackground.cgColor
        thredBackgroundView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        thredBackgroundView.layer.borderWidth = thredBackgroundView.frame.height / 17.75
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        thredBackgroundView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        signInBtn.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
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

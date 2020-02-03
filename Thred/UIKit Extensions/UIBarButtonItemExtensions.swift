//
//  UIBarButtonItemExtensions.swift
//  Thred
//
//  Created by Artak on 2019-10-23.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit

extension UIBarButtonItem{
    
    func hideButton(){
        self.isEnabled = false
        self.tintColor = UIColor.clear
    }
    
    func showButton(color: UIColor){
        self.isEnabled = true
        self.tintColor = color
    }
}

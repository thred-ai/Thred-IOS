//
//  UIButtonExtensions.swift
//  Thred
//
//  Created by Artak on 2019-10-23.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit

extension UIButton{
    
    func updateFollowBtn(following: Bool){
        switch following{
        case true:
            self.setTitle("Following", for: .normal)
            self.backgroundColor = UIColor.green
            self.tintColor = UIColor.white
            print("following")
        case false:
            self.setTitle("Follow", for: .normal)
            self.backgroundColor = UIColor.init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
            self.tintColor = UIColor.blue.withAlphaComponent(0.8)
            print("not following")
        }
    }
}

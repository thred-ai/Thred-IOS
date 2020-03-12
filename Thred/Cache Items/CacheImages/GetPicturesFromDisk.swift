//
//  GetPicturesFromDisk.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    func loadImage(withName name: String, type: String) -> UIImage? {
        
        if let url = type.determineFolder()?.appendingPathComponent(name){
            return UIImage.init(contentsOfFile: url.path)
        }
        else{
            return nil
        }
    }
}
   // returns an image if there is one with the given name, otherwise returns nil


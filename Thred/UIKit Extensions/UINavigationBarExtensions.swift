//
//  UINavigationBarExtensions.swift
//  Thred
//
//  Created by Artak on 2019-10-26.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit


extension UINavigationBar {
    func transparentNavigationBar() {
        self.setBackgroundImage(UIImage.init(), for: .default)
        self.shadowImage = UIImage.init()
        self.isTranslucent = true
    }
}

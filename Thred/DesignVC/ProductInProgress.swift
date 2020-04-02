//
//  ProductInProgress.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

class ProductInProgress{
    
    var templateColor: String!
    var design: UIImage!
    var uid: String!
    var caption: String!
    var name: String!
    var productID: String?
    var price: Double?
    
    init(templateColor: String!, design: UIImage!, uid: String!, caption: String!, name: String!, price: Double!, productID: String?) {
        self.templateColor = templateColor
        self.design = design
        self.uid = uid
        self.caption = caption
        self.name = name
        self.price = price
        self.productID = productID
    }
    
    convenience init() {
        self.init(templateColor: nil, design: nil, uid: nil, caption: nil, name: nil, price: nil, productID: nil)
    }
}

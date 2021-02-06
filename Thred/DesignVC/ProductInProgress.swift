//
//  ProductInProgress.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

class Design: Codable{
    
    var img: Data?
    var side: TemplateSide!
    
    init(img: Data?, side: TemplateSide?) {
        self.img = img
        self.side = side
    }
    
}

class ProductInProgress: Codable{
    
    var templateColor: String!
    var designs = [Design?]()
    var uid: String!
    var caption: String!
    var name: String!
    var productID: String?
    var price: Double?
    var display: Data!
    var isPublic: Bool!
    var productType: String!
    var displaySide: String!
    
    init(templateColor: String!, designs: [Design?], uid: String!, caption: String!, name: String!, price: Double!, productID: String?, display: Data?, isPublic: Bool?, productType: String?, displaySide: String?) {
        self.templateColor = templateColor
        self.designs = designs
        self.uid = uid
        self.caption = caption
        self.name = name
        self.price = price
        self.productID = productID
        self.display = display
        self.isPublic = isPublic
        self.productType = productType
        self.displaySide = displaySide ?? "front"
    }
    
    convenience init() {
        self.init(templateColor: nil, designs: [], uid: nil, caption: nil, name: nil, price: nil, productID: nil, display: nil, isPublic: nil, productType: nil, displaySide: nil)
    }
}

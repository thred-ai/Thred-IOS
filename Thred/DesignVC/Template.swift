//
//  Template.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import UIKit

class Colors: Codable{
    
    var code: String?
    var display: String?
    var rgb: [Double]?
    var img: Data?
    var imgBack: Data?
    
    
    init(code: String?, display: String?, rgb: [Double]?, img: Data?, imgBack: Data?) {
        self.code = code
        self.display = display
        self.rgb = rgb
        self.img = img
        self.imgBack = imgBack
    }
}

class TemplateSide: Codable{
    
    var name: String?
    var heightCM: Double!
    var widthCM: Double!
    var widthMultiplier: Double!
    var centerYConst: Double!
    var centerXConst: Double!
    var useReverseAspect: Bool!
    var rotation: Double!
    
    var aspectRatio: CGFloat {
        if useReverseAspect ?? false{
            return CGFloat(widthCM / heightCM)
        }
        return CGFloat(heightCM / widthCM)
    }
    
    var sideAspectRatio: CGFloat? {
        if useReverseAspect ?? false{
            return CGFloat(widthCM / heightCM)
        }
        return CGFloat(heightCM / widthCM)
    }
    
    var regularAspectRatio: CGFloat {
        return CGFloat(heightCM / widthCM)
    }
    
    var reversedAspectRatio: CGFloat {
        return CGFloat(widthCM / heightCM)
    }
    
    init(name: String?, heightCM: Double!, widthCM: Double!, widthMultiplier: Double!, centerY: Double!, useReverseAspect: Bool?, centerXConst: Double!, rotation: Double!) {
        self.name = name
        self.heightCM = heightCM
        self.widthCM = widthCM
        self.widthMultiplier = widthMultiplier
        self.centerYConst = centerY
        self.useReverseAspect = useReverseAspect
        self.centerXConst = centerXConst
        self.rotation = rotation
    }
}

class Template: Equatable, Codable, NSCopying{
    
    var templateID: String!
    var templateDisplayName: String!
    var info: String?
    var colors: [Colors]! = [Colors]()
    var sizes: [String]!
    var minPrice: Double?
    var productCode: String?
    var category: String?
    var moreInfo: String?
    var isDiscount: Bool?
    var discountPrice: Double?
    var supportedSides = [TemplateSide]()
    var extraCost: Double!

    
    init(templateID: String!, templateDisplayName: String!, colors: [Colors], info: String?, minPrice: Double?, productCode: String?, sizes: [String]!, category: String?, moreInfo: String?, discountInfo: (Bool?, Double?)?, supportedSides: [TemplateSide], extraCost: Double?){
        self.templateID = templateID
        self.templateDisplayName = templateDisplayName
        self.colors = colors
        self.info = info
        self.minPrice = (minPrice ?? 0) / 100
        self.productCode = productCode
        self.sizes = sizes
        self.category = category
        self.moreInfo = moreInfo
        self.isDiscount = discountInfo?.0
        self.discountPrice = (discountInfo?.1 ?? 0) / 100
        self.supportedSides = supportedSides
        self.extraCost = (extraCost ?? 0) / 100
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Template(templateID: templateID, templateDisplayName: templateDisplayName, colors: colors, info: info, minPrice: (minPrice ?? 0) * 100, productCode: productCode, sizes: sizes, category: category, moreInfo: moreInfo, discountInfo: (isDiscount, (discountPrice ?? 0) * 100), supportedSides: supportedSides, extraCost: extraCost)
        return copy
    }
    
    convenience init() {
        self.init(templateID: nil, templateDisplayName: nil, colors: [], info: nil, minPrice: nil, productCode: nil, sizes: [], category: nil, moreInfo: nil, discountInfo: nil, supportedSides: [], extraCost: nil)
    }
    
    static func == (lhs: Template, rhs: Template) -> Bool {
        return true
    }
}

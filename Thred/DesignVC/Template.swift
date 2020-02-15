//
//  Template.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation

class Template: Codable{
    
    var templateID: String!
    var templateData: Data!
    
    init(templateID: String!, templateData: Data!){
        self.templateID = templateID
        self.templateData = templateData
    }
    
    convenience init() {
        self.init(templateID: nil, templateData: nil)
    }
    
    static func == (lhs: Template, rhs: Template) -> Bool {
        return true
    }
}

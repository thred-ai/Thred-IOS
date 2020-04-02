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
    var templateDisplayName: String!
    
    init(templateID: String!, templateDisplayName: String!){
        self.templateID = templateID
        self.templateDisplayName = templateDisplayName
    }
    
    convenience init() {
        self.init(templateID: nil, templateDisplayName: nil)
    }
    
    static func == (lhs: Template, rhs: Template) -> Bool {
        return true
    }
}

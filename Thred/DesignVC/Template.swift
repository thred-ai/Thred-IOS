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
    var hasFemale: Bool!
    
    init(templateID: String!, templateDisplayName: String!, hasFemale: Bool!){
        self.templateID = templateID
        self.templateDisplayName = templateDisplayName
        self.hasFemale = hasFemale
    }
    
    convenience init() {
        self.init(templateID: nil, templateDisplayName: nil, hasFemale: nil)
    }
    
    static func == (lhs: Template, rhs: Template) -> Bool {
        return true
    }
}

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
    
    init(templateID: String!){
        self.templateID = templateID
    }
    
    convenience init() {
        self.init(templateID: nil)
    }
    
    static func == (lhs: Template, rhs: Template) -> Bool {
        return true
    }
}

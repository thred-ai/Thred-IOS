//
//  Message.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-28.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

class TextMessage: Equatable{
    
    static func == (lhs: TextMessage, rhs: TextMessage) -> Bool {
        return true
    }
    
    var uid = String()
    var message: String?
    var textID = String()
    var isPic: Bool
    var dp: UIImage?
    var fullname: String?
    var username: String?
    var timestamp = String()
    var dpID: String?
    var index: Int?
    var messageImg: UIImage?
    var aspectRatio: CGFloat?
    var estimatedHeight: CGFloat?
    var date: String?

    init(uid: String, message: String?, textID: String, isPic: Bool, dp: UIImage?, fullname: String?, username: String?, timestamp: String, dpID: String?, index: Int?, messageImg: UIImage?, aspectRatio: CGFloat?, estimatedHeight: CGFloat?, date: String?) {
        
        self.uid = uid
        self.message = message
        self.textID = textID
        self.isPic = isPic
        self.dp = dp
        self.fullname = fullname
        self.username = username
        self.timestamp = timestamp
        self.dpID = dpID
        self.index = index
        self.messageImg = messageImg
        self.aspectRatio = aspectRatio
        self.estimatedHeight = estimatedHeight
        self.date = date
        
    }
    
    convenience init(){
        self.init(uid: "", message: nil, textID: "", isPic: false, dp: nil, fullname: nil, username: nil, timestamp: "", dpID: nil, index: nil, messageImg: nil, aspectRatio: nil, estimatedHeight: nil, date: nil)
    }
}

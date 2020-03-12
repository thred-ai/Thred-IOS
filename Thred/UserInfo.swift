//
//  userInfo.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

let defaultDP = UIImage.init(named: "default_DP.png")

class UserInfo{
   
    var uid: String = String()
    var dp: UIImage?
    var dpID: String = String()
    var username: String = String()
    var fullName: String = String()
    var bio: String = String()
    var notifID: String = String()
    var userFollowing: [String]? = [String]()
    var userLiked: [String]? = [String]()
    var pendingLiked: [String : Bool]? = [String : Bool]()
    
    init(uid: String, dp: UIImage?, dpID: String, username: String, fullName: String, bio: String, notifID: String, userFollowing: [String]?, userLiked: [String]?) {
        
        self.uid = uid
        self.dp = dp
        self.dpID = dpID
        self.username = username
        self.fullName = fullName
        self.bio = bio
        self.notifID = notifID
        self.userFollowing = userFollowing
        self.userLiked = userLiked
    }
    
    convenience init() {
        self.init(uid: "", dp: nil,  dpID: "", username: "", fullName: "", bio: "", notifID: "", userFollowing: [], userLiked: [])
    }
}

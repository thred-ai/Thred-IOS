//
//  userInfo.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

let defaultDP = UIImage.init(named: "default_DP")?.jpegData(compressionQuality: 1.0)

class UserInfo: Codable{
   
    var uid: String?
    var dp: Data?
    var dpID: String?
    var username: String?
    var fullName: String?
    var bio: String?
    var notifID: String?
    var userFollowing = [String]()
    var userLiked: [String]
    var followerCount = Int()
    var postCount = Int()
    var followingCount = Int()
    var pendingLiked = [String : Bool]()
    var usersBlocking = [String]()
    var profileLink: URL?
    var verified = Bool()
    var postNotifsList = [String]()
    
    init(uid: String?, dp: Data?, dpID: String?, username: String?, fullName: String?, bio: String?, notifID: String?, userFollowing: [String], userLiked: [String], followerCount: Int, postCount: Int, followingCount: Int, usersBlocking: [String], profileLink: URL?, verified: Bool?) {
        
        self.uid = uid
        self.dp = dp
        self.dpID = dpID
        self.username = username
        self.fullName = fullName
        self.bio = bio
        self.notifID = notifID
        self.userFollowing = userFollowing
        self.userLiked = userLiked
        self.followerCount = followerCount
        self.postCount = postCount
        self.followingCount = followingCount
        self.usersBlocking = usersBlocking
        self.profileLink = profileLink
        self.verified = verified ?? false
    }
    
    convenience init() {
        self.init(uid: nil, dp: nil,  dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
    }
}

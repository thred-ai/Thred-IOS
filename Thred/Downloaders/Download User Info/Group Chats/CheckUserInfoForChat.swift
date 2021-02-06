//
//  DownloadUserInfoForProduct.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore
import SDWebImage

extension UITableView{
    
    func checkAndDownloadUserInfoInFullVC(user: Product, dp: UIImageView, userLbl: UILabel, fullLbl: UILabel, picCell: ProductCell?, fullVC: FullProductVC){
        
        switch user.userInfo.uid{
        case pUserInfo.uid:
            guard let imgData = pUserInfo.dp else{fallthrough}
            dp.image = UIImage(data: imgData)
            user.userInfo.fullName = pUserInfo.fullName
            user.userInfo.username = pUserInfo.username
            fullLbl.text = pUserInfo.fullName
            if pUserInfo.verified{
                fullLbl.setVerified(name: user.userInfo.fullName ?? "")
                user.userInfo.verified = pUserInfo.verified
            }
            userLbl.text = "@" + (pUserInfo.username ?? "null")
            picCell?.removeLabelLoad()
            picCell?.removeDpLoad()
        default:
            switch (user.userInfo.fullName, user.userInfo.username){
            case (.some, .some):
                if let imageData = user.userInfo.dp, let imageFromCache = UIImage(data: imageData) ?? cache.imageFromCache(forKey: user.userInfo.dpID){
                    dp.image = imageFromCache
                    fullLbl.text = user.userInfo.fullName
                    if user.userInfo.verified{
                        fullLbl.setVerified(name: user.userInfo.fullName ?? "")
                    }
                    userLbl.text = "@" + (user.userInfo.username ?? "null")
                    picCell?.removeLabelLoad()
                    picCell?.removeDpLoad()
                }
                else{ fallthrough }
            default:
                if userLbl.text?.isEmpty ?? true && fullLbl.text?.isEmpty ?? true{
                    picCell?.nameSkeletonView.startAnimating()
                }
                
                picCell?.dpSkeletonView.startAnimating()
                beginDownloadingUserInfo(uid: user.userInfo.uid ?? "", userVC: nil, feedVC: nil, friendVC: nil, fullVC: fullVC, section: 0)
            }
        }
    }
    
    func checkAndDownloadUserInfoInFeed(feed: FeedVC?, user: Product, dp: UIImageView, userLbl: UILabel, fullLbl: UILabel, picCell: ProductCell?){
        
        if user.userInfo.uid == pUserInfo.uid, let username = pUserInfo.username, let fullname = pUserInfo.fullName, let imgData = pUserInfo.dp{
            user.userInfo.username = username
            user.userInfo.fullName = fullname
            user.userInfo.dpID = pUserInfo.dpID
            fullLbl.text = fullname
            if pUserInfo.verified{
                fullLbl.setVerified(name: pUserInfo.fullName ?? "")
            }
            userLbl.text = "@\(username)"
            picCell?.removeLabelLoad()
            dp.image = UIImage(data: imgData)
            picCell?.removeDpLoad()
        }
        else{
            DispatchQueue(label: "cache").async {
                switch (user.userInfo.fullName, user.userInfo.username){
                    
                case (.some, .some):
                    
                    if let imageData = user.userInfo.dp, let imageFromCache = UIImage(data: imageData) ?? cache.imageFromCache(forKey: user.userInfo.dpID){
                        DispatchQueue.main.async {
                            dp.image = imageFromCache
                            fullLbl.text = user.userInfo.fullName
                            if user.userInfo.verified{
                                fullLbl.setVerified(name: user.userInfo.fullName ?? "")
                            }
                            userLbl.text = "@" + (user.userInfo.username ?? "null")
                            picCell?.removeLabelLoad()
                            picCell?.removeDpLoad()
                        }
                    }
                    else{
                        if user.userInfo.uid == pUserInfo.uid, let imgData = pUserInfo.dp{
                            DispatchQueue.main.async {
                                dp.image = UIImage(data: imgData)
                                fullLbl.text = pUserInfo.fullName
                                if user.userInfo.verified{
                                    fullLbl.setVerified(name: pUserInfo.fullName ?? "")
                                }
                                userLbl.text = "@" + (pUserInfo.username ?? "null")
                                picCell?.removeLabelLoad()
                                picCell?.removeDpLoad()
                            }
                        }
                        else{
                            fallthrough
                        }
                    }
                default:
                    switch feed?.loadedProducts.contains(where: {$0.userInfo.uid == user.userInfo.uid}){
                    case true:
                        let cachedUserInfo = feed?.loadedProducts.first(where: {$0.userInfo.uid == user.userInfo.uid && $0.userInfo.username != nil})
                        user.userInfo.username = cachedUserInfo?.userInfo.username
                        user.userInfo.fullName = cachedUserInfo?.userInfo.fullName
                        if user.userInfo.verified{
                            fullLbl.setVerified(name: pUserInfo.fullName ?? "")
                        }
                        user.userInfo.dpID = cachedUserInfo?.userInfo.dpID
                        if let fullName = cachedUserInfo?.userInfo.fullName{
                            DispatchQueue.main.async {
                                fullLbl.text = fullName
                                if user.userInfo.verified{
                                    fullLbl.setVerified(name: pUserInfo.fullName ?? "")
                                }
                                picCell?.removeLabelLoad()
                            }
                        }
                        else{
                            fallthrough
                        }
                        if let username = cachedUserInfo?.userInfo.username{
                            DispatchQueue.main.async {
                                userLbl.text = "@" + (username)
                                picCell?.removeLabelLoad()
                            }
                        }
                        else{
                            fallthrough
                        }
                        
                        if let imageData = user.userInfo.dp, let imageFromCache = UIImage(data: imageData) ?? cache.imageFromCache(forKey: user.userInfo.dpID){
                            DispatchQueue.main.async {
                                dp.image = imageFromCache
                                picCell?.removeDpLoad()
                            }
                        }
                        else{
                            fallthrough
                        }
                    default:
                        
                        DispatchQueue.main.async {
                            if userLbl.text?.isEmpty ?? true && fullLbl.text?.isEmpty ?? true{
                                picCell?.nameSkeletonView.startAnimating()
                            }
                            picCell?.dpSkeletonView.startAnimating()
                            if !(feed?.downloadingProfiles.contains(user.userInfo.uid ?? "") ?? false){
                                feed?.downloadCount += 1
                                feed?.downloadingProfiles.append(user.userInfo.uid ?? "")
                                self.beginDownloadingUserInfo(uid: user.userInfo.uid ?? "", userVC: nil, feedVC: feed, friendVC: nil, fullVC: nil, section: 0)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkAndDownloadUserInfoInProfile(userVC: UserVC?, friendVC: FriendVC?, user: Product, dp: UIImageView, userLbl: UILabel, fullLbl: UILabel,picCell: ProductCell?, userInfo: UserInfo){
        
        if user.userInfo.uid == userInfo.uid{
            if let imgData = userInfo.dp{
                dp.image = UIImage(data: imgData)
            }
            user.userInfo.fullName = userInfo.fullName
            
            user.userInfo.username = userInfo.username
            userLbl.text = "@" + (userInfo.username ?? "null")
            fullLbl.text = userInfo.fullName
            if userInfo.verified{
                user.userInfo.verified = true
                fullLbl.setVerified(name: userInfo.fullName ?? "")
            }
            picCell?.removeLabelLoad()
            picCell?.removeDpLoad()
        }
        else{
            DispatchQueue(label: "cache").async {
                switch user.userInfo.dp{
                case let img:
                    let username = user.userInfo.username
                    let fullname = user.userInfo.fullName
                    if username == nil || fullname == nil || img == nil{
                        fallthrough
                    }
                    let imageFromCache = UIImage(data: img!) ?? cache.imageFromCache(forKey: user.userInfo.dpID)
                    
                    DispatchQueue.main.async {
                        dp.image = imageFromCache
                        userLbl.text = "@" + (username ?? "null")
                        fullLbl.text = fullname
                        if userInfo.verified{
                            user.userInfo.verified = true
                            fullLbl.setVerified(name: fullname ?? "")
                        }
                        picCell?.removeLabelLoad()
                        picCell?.removeDpLoad()
                    }
                default:
                    DispatchQueue.main.async {
                        picCell?.nameSkeletonView.startAnimating()
                        picCell?.dpSkeletonView.startAnimating()
                        
                        if !(userVC?.downloadingProfiles.contains(user.userInfo.uid ?? "") ?? friendVC?.downloadingProfiles.contains(user.userInfo.uid ?? "") ?? false){
                            userVC?.downloadingProfiles.append(user.userInfo.uid ?? "")
                            friendVC?.downloadingProfiles.append(user.userInfo.uid ?? "")

                            self.beginDownloadingUserInfo(uid: user.userInfo.uid ?? "", userVC: userVC, feedVC: nil, friendVC: nil, fullVC: nil, section: 0)
                        }
                    }
                }
            }
        }
    }
}

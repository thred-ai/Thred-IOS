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
        
        switch user.uid{
        case userInfo.uid:
            dp.image = userInfo.dp
            fullLbl.text = userInfo.fullName
            userLbl.text = "@" + (userInfo.username ?? "null")
            picCell?.removeLabelLoad()
            picCell?.removeDpLoad()
        default:
            switch (user.fullName, user.username){
            case (.some, .some):
                if let imageFromCache = cache.imageFromCache(forKey: user.userImageID){
                    dp.image = imageFromCache
                    fullLbl.text = user.fullName
                    userLbl.text = "@" + (user.username ?? "null")
                    picCell?.removeLabelLoad()
                    picCell?.removeDpLoad()
                }
                else{ fallthrough }
            default:
                if userLbl.text?.isEmpty ?? true && fullLbl.text?.isEmpty ?? true{
                    picCell?.nameSkeletonView.startAnimating()
                }
                
                picCell?.dpSkeletonView.startAnimating()
                guard let downloader = fullVC.downloader
                    else{return}
                beginDownloadingUserInfo(uid: user.uid, downloader: downloader, userVC: nil, feedVC: nil, friendVC: nil, fullVC: fullVC, section: 0)
            }
        }
    }
    
    func checkAndDownloadUserInfoInFeed(feed: FeedVC?, user: Product, dp: UIImageView, userLbl: UILabel, fullLbl: UILabel, picCell: ProductCell?){
        
        if user.uid == userInfo.uid, let username = userInfo.username, let fullname = userInfo.fullName{
            user.username = username
            user.fullName = fullname
            user.userImageID = userInfo.dpID
            fullLbl.text = fullname
            userLbl.text = "@\(username)"
            dp.image = userInfo.dp
            picCell?.removeLabelLoad()
            picCell?.removeDpLoad()
        }
        else{
            switch (user.fullName, user.username){
                
            case (.some, .some):
                
                if let imageFromCache = cache.imageFromCache(forKey: user.userImageID){
                    dp.image = imageFromCache
                    fullLbl.text = user.fullName
                    userLbl.text = "@" + (user.username ?? "null")
                    picCell?.removeLabelLoad()
                    picCell?.removeDpLoad()
                }
                else{
                    if user.uid == userInfo.uid, userInfo.dp != nil{
                        dp.image = userInfo.dp
                        fullLbl.text = userInfo.fullName
                        userLbl.text = "@" + (userInfo.username ?? "null")
                        picCell?.removeLabelLoad()
                        picCell?.removeDpLoad()
                    }
                    else{
                        fallthrough
                    }
                }
            default:
                switch feed?.loadedProducts.contains(where: {$0.uid == user.uid}){
                case true:
                    let cachedUserInfo = feed?.loadedProducts.first(where: {$0.uid == user.uid && $0.username != nil})
                    user.username = cachedUserInfo?.username
                    user.fullName = cachedUserInfo?.fullName
                    user.userImageID = cachedUserInfo?.userImageID
                    if let fullName = cachedUserInfo?.fullName{
                        fullLbl.text = fullName
                        picCell?.removeLabelLoad()
                    }
                    else{
                        fallthrough
                    }
                    if let username = cachedUserInfo?.username{
                        userLbl.text = "@" + (username)
                        picCell?.removeLabelLoad()
                    }
                    else{
                        fallthrough
                    }
                    if let img = cache.imageFromCache(forKey: cachedUserInfo?.userImageID){
                        dp.image = img
                        picCell?.removeDpLoad()
                    }
                    else{
                        fallthrough
                    }
                default:
                    
                    if userLbl.text?.isEmpty ?? true && fullLbl.text?.isEmpty ?? true{
                        picCell?.nameSkeletonView.startAnimating()
                    }
                    
                    picCell?.dpSkeletonView.startAnimating()
                    
                    if !(feed?.downloadingProfiles.contains(user.uid) ?? false){
                        feed?.downloadCount += 1

                        feed?.downloadingProfiles.append(user.uid)

                        guard let downloader = feed?.downloader
                            else{return}
                        
                        beginDownloadingUserInfo(uid: user.uid, downloader: downloader, userVC: nil, feedVC: feed, friendVC: nil, fullVC: nil, section: 0)
                    }
                }
            }
        }
    }
    
    func checkAndDownloadUserInfoInProfile(userVC: UserVC?, friendVC: FriendVC?, user: Product, dp: UIImageView, userLbl: UILabel, fullLbl: UILabel,picCell: ProductCell?, userInfo: UserInfo){
        
        if user.uid == userInfo.uid{
            if userInfo.dp != nil{
                dp.image = userInfo.dp
            }
            userLbl.text = "@" + (userInfo.username ?? "null")
            fullLbl.text = userInfo.fullName
            picCell?.removeLabelLoad()
            picCell?.removeDpLoad()
        }
        else{
            switch cache.imageFromCache(forKey: user.picID){
            case let img:
                let username = user.username
                let fullname = user.fullName
                if username == nil || fullname == nil{
                    fallthrough
                }
                dp.image = img
                userLbl.text = "@" + (username ?? "null")
                fullLbl.text = fullname
                picCell?.removeLabelLoad()
                picCell?.removeDpLoad()
            default:
                picCell?.nameSkeletonView.startAnimating()
                picCell?.dpSkeletonView.startAnimating()
                
                if !(userVC?.downloadingProfiles.contains(user.uid) ?? friendVC?.downloadingProfiles.contains(user.uid) ?? false){
                    userVC?.downloadingProfiles.append(user.uid)
                    friendVC?.downloadingProfiles.append(user.uid)

                    beginDownloadingUserInfo(uid: user.uid, downloader: userVC?.downloader ?? friendVC?.downloader, userVC: userVC, feedVC: nil, friendVC: nil, fullVC: nil, section: 0)
                }
            }
        }
    }
}

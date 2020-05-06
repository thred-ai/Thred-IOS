//
//  UserInfoDownloader.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-16.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import Firebase
import FirebaseFirestore
var downloader = SDWebImageDownloader.shared

extension UITableView{

    func beginDownloadingUserInfo(uid: String, userVC: UserVC?, feedVC: FeedVC?, friendVC: FriendVC?, fullVC: FullProductVC?, section: Int){
        print(uid)
        
        guard let vc = feedVC ?? fullVC ?? friendVC ?? userVC else{return}
        vc.downloadUserInfo(uid: uid, userVC: userVC, feedVC: feedVC, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: {[weak self] uid, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postCount, followersCount, followingCount in
            
            if username != nil{
                if userVC != nil{
                    userVC?.downloadingProfiles.removeAll(where: {$0 == uid})
                }
                if feedVC != nil{
                    feedVC?.downloadingProfiles.removeAll(where: {$0 == uid})
                }
                if friendVC != nil{
                    friendVC?.downloadingProfiles.removeAll(where: {$0 == uid})
                }
                
                self?.setCellUserInfo(image: imgData, info: [uid, fullName, username, dpUID], feedVC: feedVC, userVC: userVC, friendVC: friendVC, fullVC: fullVC, section: section)
            }
        })
    }
    
    
    func setCellUserInfo(image: Data?, info: [String?], feedVC: FeedVC?, userVC: UserVC?, friendVC: FriendVC?, fullVC: FullProductVC?, section: Int){
        
        guard let uid = info[0] else{return}
        let fullname = info[1]
        let username = info[2]
        let dpUID = info[3]
        

        let sameIDs = userVC?.loadedProducts.filter({$0.uid == uid}) ?? feedVC?.loadedProducts.filter({$0.uid == uid}) ?? friendVC?.loadedProducts.filter({$0.uid == uid})
        for sameID in sameIDs ?? []{
            sameID.username = username
            sameID.fullName = fullname
            sameID.userImageID = dpUID
        }
        NoProductsLoaded:
        
        if feedVC != nil{
            guard let loadedProducts = feedVC?.loadedProducts else{break NoProductsLoaded}

            if !(loadedProducts.contains(where: {$0.fullName == nil && $0.username == nil})){
                //feedVC?.removeFile(withName: "CachedFeedProducts")
                loadedProducts.saveAllObjects(type: "FeedProducts")
            }
            DispatchQueue.main.async {
                self.setForProduct(uid: uid, fullname: fullname, username: username, image: image, userVC: userVC, friendVC: friendVC, feedVC: feedVC)
            }
        }
        else if friendVC != nil{
            DispatchQueue.main.async {
                self.setForProduct(uid: uid, fullname: fullname, username: username, image: image, userVC: userVC, friendVC: friendVC, feedVC: feedVC)
            }
        }
        else if fullVC != nil{
            DispatchQueue.main.async {
                if let mainProductCell = self.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProductCell{
                    
                    if let user = username, let full = fullname{
                        fullVC?.fullProduct.fullName = full
                        fullVC?.fullProduct.username = username
                        mainProductCell.username.text = "@" + user
                        mainProductCell.fullName.text = full
                        mainProductCell.removeLabelLoad()
                    }
                    if let img = image{
                        mainProductCell.userImage.image = UIImage(data: img)
                        mainProductCell.removeDpLoad()
                    }
                }
            }
        }
    
    }
    
    func setForProduct(uid: String, fullname: String?, username: String?, image: Data?, userVC: UserVC?, friendVC: FriendVC?, feedVC: FeedVC?){
        
        if let products = userVC?.loadedProducts ?? friendVC?.loadedProducts ?? feedVC?.loadedProducts{
            
            if let indices = indexPathsForVisibleRows{
                for index in indices{
                    if products[index.row].uid == uid{
                        if let cell = cellForRow(at: index){
                            switch cell{
                            case let c as ProductCell:
                                c.fullName.text = fullname
                                c.username.text = "@" + (username ?? "null")
                                c.removeLabelLoad()
                                if let img = image{
                                    c.userImage.image = UIImage(data: img)
                                    c.removeDpLoad()
                                }
                            default:
                                continue
                            }
                        }
                    }
                }
            }
        }
    }
}




extension UITableViewCell{
    
    
    func removeLabelLoad(){
        if let c = self as? ProductCell{
            c.nameSkeletonView.stopAnimating()
            c.nameSkeletonView.layer.mask = nil
        }
    }
    func removeDpLoad(){
        if let c = self as? ProductCell{
            c.dpSkeletonView.stopAnimating()
            c.dpSkeletonView.layer.mask = nil
        }
    }
}


extension UIViewController{
    func downloadUserInfo(uid: String?, userVC: UserVC?, feedVC: FeedVC?, downloadingPersonalDP: Bool, doNotDownloadDP: Bool, userInfoToUse: UserInfo?, queryOnUsername: Bool, completed: @escaping (String?, String?, String?, String?, String?, String?, Data?, [String], [String], Int, Int, Int) -> ()){
        
        let ref = Firestore.firestore().collection("Users")

        var query: Query!
        
        if queryOnUsername{
            guard let username = userInfoToUse?.username?.replacingOccurrences(of: " ", with: "") else{
            return}
            print(username)
            
            query = ref.whereField("Username", isEqualTo: username)
        }
        else{
            guard let userUID = uid else{
                
                return}
            query = ref.whereField(FieldPath.documentID(), isEqualTo: userUID)
        }
        
        query.getDocuments(){(querySnaps, err) in
            if err != nil{
                print("Error getting documents: \(err?.localizedDescription ?? "")") // LOCALIZED DESCRIPTION OF ERROR
                completed(nil, nil, nil, nil, nil, nil, userInfoToUse?.dp ?? defaultDP, [], [], 0, 0, 0)
                return
            }
            else{
                
                guard let snapDocs = querySnaps?.documents, !snapDocs.isEmpty else{
                    completed(nil, nil, nil, nil, nil, nil, userInfoToUse?.dp ?? defaultDP, [], [], 0, 0, 0)
                    return
                }
                
                for document in snapDocs{
                    let dpUID = document["ProfilePicID"] as? String //UID OF COMMENT IMAGE
                    let username = document["Username"] as? String //COMMENTER'S USERNAME
                    let fullName = document["Full_Name"] as? String
                    let bio = document["Bio"] as? String
                    let notifID = document["Notification ID"] as? String
                    let userFollowing = (document["Following_List"] as? [String]) ?? []
                    let usersBlocking = (document["Users_Blocking"] as? [String]) ?? []
                    let followerCount = (document["Followers_Count"] as? Int) ?? 0
                    let followingCount = (document["Following_Count"] as? Int) ?? 0
                    let postCount = (document["Posts_Count"] as? Int) ?? 0
                    if userInfo.usersBlocking.contains(document.documentID){
                        completed(document.documentID, fullName, username, nil, notifID, bio, nil, userFollowing, usersBlocking, postCount, followerCount, followingCount)
                        return
                    }
                    
                    
                    if doNotDownloadDP{
                        completed(document.documentID, fullName, username, nil, notifID, bio, nil, userFollowing, usersBlocking, postCount, followerCount, followingCount)
                        return
                    }
                    var options = SDWebImageOptions(arrayLiteral: [.scaleDownLargeImages, .continueInBackground])
                    var storageRef: StorageReference?
                    storageRef = Storage.storage().reference().child("Users").child(document.documentID).child("profile_pic-" + (dpUID ?? "") + ".jpeg") //STORAGE REFERENCE OF COMMENT IMAGE
                    
                    if downloadingPersonalDP{
                        options.insert(.refreshCached)
                    }
                    
                    if let image = cache.imageFromCache(forKey: dpUID){
                        completed(document.documentID, fullName, username, dpUID, notifID, bio, image.jpegData(compressionQuality: 1.0), userFollowing, usersBlocking, postCount, followerCount, followingCount)
                        return
                    }
                    else{
                        completed(document.documentID, fullName, username, dpUID, notifID, bio, nil, userFollowing, usersBlocking, postCount, followerCount, followingCount)
                    }
                    storageRef?.downloadURL(completion: { url, error in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                            return
                        }
                        else{
                            downloader.requestImage(with: url, options: options, context: nil, progress: nil, completed: { (image, data, error, finished) in
                                  if finished{
                                      if error != nil{
                                          print(error?.localizedDescription ?? "")
                                          return
                                      }
                                      else{
                                        if let imgData = data{
                                            if userVC != nil || feedVC != nil{
                                                cache.storeImageData(toDisk: imgData, forKey: dpUID)
                                            }
                                            completed(document.documentID, fullName, username, dpUID, notifID, bio, data, userFollowing, usersBlocking, postCount, followerCount, followingCount)
                                        }
                                    }
                                }
                            })
                        }
                    })
                }
            }
        }
    }
}

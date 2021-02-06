//
//  SetUpPictureProduct.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import FirebaseFirestore
import FirebaseDynamicLinks
import FirebaseStorage
import ColorCompatibility

extension UITableView{
    
    func checkAndDownloadUserInfoForTextMsg(textMsg: TextMessage, nameLbl: UILabel, dp: UIImageView, messages: [[TextMessage]], chatVC: ChatVC, cell: UITableViewCell?, index: Int, section: Int){
                
        cell?.addLabel(section: section, nameLbl: nameLbl, textMsg: textMsg, chatVC: chatVC, cell: cell)

        cell?.addUserImage(section: section, dp: dp, textMsg: textMsg, chatVC: chatVC)
        
        if textMsg.username != nil || textMsg.fullname != nil{
            cell?.removeLabelLoad()
        }
        if textMsg.dp != nil{
            cell?.removeDpLoad()
        }
        else{
            switch messages.firstIndex(where: {$0.contains(where: {$0.uid == textMsg.uid})}){
                
            case let m:
                guard let index = m else{
                    
                    fallthrough}
                if let cachedUserInfo = messages[index].first(where: {$0.uid == textMsg.uid && $0.username != nil}){
                    if let cachedUserImg = cachedUserInfo.dp{
                        textMsg.username = cachedUserInfo.username
                        textMsg.dp = cachedUserImg
                        textMsg.fullname = cachedUserInfo.fullname
                        textMsg.dpID = cachedUserInfo.dpID
                        cell?.addLabel(section: section, nameLbl: nameLbl, textMsg: textMsg, chatVC: chatVC, cell: cell)
                        cell?.addUserImage(section: section, dp: dp, textMsg: textMsg, chatVC: chatVC)
                        cell?.removeLabelLoad()
                        cell?.removeDpLoad()
                    }
                    else{
                        fallthrough
                    }
                }
                else{
                    fallthrough
                }
            default:
                cell?.addLabelAnimations(allMessages: chatVC.allMessages, index: index, section: section, uid: textMsg.uid)
                cell?.addPicAnimations(allMessages: chatVC.allMessages, index: index, section: section, uid: textMsg.uid)

                if !(chatVC.downloadingProfiles.contains(textMsg.uid)){
                    chatVC.downloadingProfiles.append(textMsg.uid)
                    beginDownloadingUserInfoText(uid: textMsg.uid, downloader: downloader, userVC: nil, feedVC: nil, friendVC: nil, chatVC: chatVC, section: section)
                }
            }
        }
    }
    
    func beginDownloadingUserInfoText(uid: String, downloader: SDWebImageDownloader?, userVC: UserVC?, feedVC: FeedVC?, friendVC: FriendVC?, chatVC: ChatVC?, section: Int){
        
        downloadUserInfoText(uid: uid, userVC: userVC, feedVC: feedVC, downloadingPersonalDP: false, downloader: downloader, userInfo: nil, completed: { fullName, username, dpUID, notifID, bio, imgData in
            
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
                if chatVC != nil{
                    chatVC?.downloadingProfiles.removeAll(where: {$0 == uid})
                }
                self.setTextCellUserInfo(data: imgData, info: [uid, fullName, username, dpUID], chatVC: chatVC, section: section)
            }
        })
    }
    
    func downloadUserInfoText(uid: String, userVC: UserVC?, feedVC: FeedVC?, downloadingPersonalDP: Bool, downloader: SDWebImageDownloader?, userInfo: UserInfo?, completed: @escaping (String?, String?, String?, String?, String?, Data?) -> ()){
        
        let ref = Firestore.firestore().collection("Users").document(uid)
        
        ref.getDocument(){(document, err) in
            if err != nil{
                print("Error getting documents: \(err?.localizedDescription ?? "")") // LOCALIZED DESCRIPTION OF ERROR
                completed(nil, nil, nil, nil, nil, pUserInfo.dp ?? defaultDP)
                return
            }
            else{
                let dpUID = document!["ProfilePicID"] as? String //UID OF COMMENT IMAGE
                let username = document!["Username"] as? String //COMMENTER'S USERNAME
                let fullName = document!["Full_Name"] as? String
                let bio = document?["Bio"] as? String
                let notifID = document?["Notification ID"] as? String

                var options = SDWebImageOptions(arrayLiteral: [.scaleDownLargeImages, .continueInBackground])
                var storageRef: StorageReference?
                
                
                if downloadingPersonalDP{
                    options.insert(.refreshCached)
                    storageRef = Storage.storage().reference().child(uid).child("profile_pic-" + (dpUID ?? "") + ".png") //STORAGE REFERENCE OF COMMENT IMAGE
                    completed(fullName, username, dpUID, notifID, bio, pUserInfo.dp ?? defaultDP)
                }
                else{
                   storageRef = Storage.storage().reference().child("Users/\(uid)").child("profile_pic-" + (dpUID ?? "") + ".jpeg") //STORAGE REFERENCE OF COMMENT IMAGE
                    completed(fullName, username, dpUID, notifID, bio, nil)
                }
                
                storageRef?.downloadURL(completion: { url, error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        return
                    }
                    else{
                        
                        downloader?.requestImage(with: url, options: options, context: nil, progress: nil, completed: { (image, data, error, finished) in
                            if error != nil{
                                print(error?.localizedDescription ?? "") //LOCALIZED DESCRIPTION OF ERROR
                                return
                            }
                            else{
                                if userVC != nil || feedVC != nil{
                                    cache.storeImageData(toDisk: data, forKey: dpUID)
                                }
                                
                                completed(fullName, username, dpUID, notifID, bio, data ?? pUserInfo.dp ?? defaultDP)
                            }
                        })
                    }
                })
            }
        }
    }
    
    
    
    func setTextCellUserInfo(data: Data?, info: [String?], chatVC: ChatVC?, section: Int){
        
        guard let uid = info[0] else{return}
        let fullname = info[1]
        let username = info[2]
        let dpUID = info[3]
/*
        let sameIDs = userVC?.loadedchats.filter({$0.uid == uid}) ?? feedVC?.loadedchats.filter({$0.uid == uid}) ?? friendVC?.loadedchats.filter({$0.uid == uid})
        for sameID in sameIDs ?? []{
            sameID.username = username
            sameID.fullName = fullname
            sameID.userImageID = dpUID
            guard let index = (userVC?.loadedchats ?? feedVC?.loadedchats ?? friendVC?.loadedchats ?? []).firstIndex(where: {$0.chatID == sameID.chatID}) else{continue}
            sameID.index = index
        }
        */
        NoChatsLoaded:
        if chatVC != nil{
            if let indices = chatVC?.allMessages.indices{
                for section in indices{
                    let sameMsgIDs = chatVC?.allMessages[section].filter({$0.uid == uid})
                    for sameMsgID in sameMsgIDs ?? []{
                        if let data = data, let imageToSet = UIImage(data: data){
                            sameMsgID.dp = imageToSet
                        }
                        sameMsgID.dpID = dpUID
                        sameMsgID.username = username
                        sameMsgID.fullname = fullname
                    }
                    DispatchQueue.main.async {
                        if let data = data, let image = UIImage(data: data){
                            self.setForMessage(sameMsgIDs: sameMsgIDs, uid: uid, chatVC: chatVC, fullname: fullname, username: username, imageToSet: image)
                        }
                    }
                }
            }
        }
            /*
        else if feedVC != nil{
            guard let loadedChats = feedVC?.loadedchats else{break NoChatsLoaded}

            if !(loadedChats.contains(where: {$0.fullName == nil && $0.username == nil})){
                //feedVC?.removeFile(withName: "CachedFeedChats")
                loadedChats.saveAllObjects(type: "FeedChats", name: "Chats")
            }
            DispatchQueue.main.async {
                self.setForChat(uid: uid, fullname: fullname, username: username, image: image, userVC: userVC, friendVC: friendVC, feedVC: feedVC)
            }
        }
        else if friendVC != nil{
            DispatchQueue.main.async {
                self.setForChat(uid: uid, fullname: fullname, username: username, image: image, userVC: userVC, friendVC: friendVC, feedVC: feedVC)
            }
        }
        */
    }
    
    func setForMessage(sameMsgIDs: [TextMessage]?, uid: String, chatVC: ChatVC?, fullname: String?, username: String?, imageToSet: UIImage?){
        
        if let indexes = indexPathsForVisibleRows{
            for index in indexes{
                if chatVC?.allMessages[index.section][index.row].uid == uid{
                    if let cell = cellForRow(at: index){
                        switch cell{
                        case let c as PicMessageCell:
                            if let name = fullname ?? username{
                                if c.nameLbl != nil{
                                    c.nameLbl.text = name
                                    c.removeLabelLoad()
                                }
                            }
                            if let image = imageToSet{
                                if c.userImgView != nil{
                                    c.userImgView.image = image
                                    c.removeDpLoad()
                                }
                            }
                        case let c as TextMessageCell:
                            if let name = fullname ?? username{
                                if c.nameLbl != nil{
                                    c.nameLbl.text = name
                                    c.removeLabelLoad()
                                }
                            }
                            if let image = imageToSet{
                                if c.userImgView != nil{
                                    c.userImgView.image = image
                                    c.removeDpLoad()
                                }
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

extension UITableViewCell{
    
    func addPicAnimations(allMessages: [[TextMessage]], index: Int, section: Int, uid: String){
        if index != 0{
            if allMessages[section][index - 1].uid != uid{
                (((self as? TextMessageCell)?.dpSkeletonView) ?? ((self as? PicMessageCell)?.dpSkeletonView))?.startAnimating()
            }
            else{
                removeDpLoad()
            }
        }
        else{
            (((self as? TextMessageCell)?.dpSkeletonView) ?? ((self as? PicMessageCell)?.dpSkeletonView))?.startAnimating()
        }
    }
    
    func addLabelAnimations(allMessages: [[TextMessage]], index: Int, section: Int, uid: String){
            if index != allMessages[section].count - 1{
                if allMessages[section][index + 1].uid != uid{
                
                (((self as? TextMessageCell)?.nameSkeletonView) ?? ((self as? PicMessageCell)?.nameSkeletonView))?.startAnimating()
            }
            else{
                removeLabelLoad()
            }
        }
        else{
            (((self as? TextMessageCell)?.nameSkeletonView) ?? ((self as? PicMessageCell)?.nameSkeletonView))?.startAnimating()
        }
    
    }

    func addUserImage(section: Int, dp: UIImageView, textMsg: TextMessage, chatVC: ChatVC){
        
        if let index = chatVC.allMessages[section].firstIndex(where: {$0.textID == textMsg.textID}){

            if index != 0{
                if chatVC.allMessages[section][index - 1].uid != textMsg.uid{
                    dp.isHidden = false
                    dp.image = textMsg.dp
                }
                else{
                    dp.isHidden = true
                }
            }
            else{
                dp.image = textMsg.dp
                dp.isHidden = false
            }
        }
    }
    
    func addLabel(section: Int, nameLbl: UILabel, textMsg: TextMessage, chatVC: ChatVC, cell: UITableViewCell?){
        
        let height = nameLbl.constraints.first(where: {$0.identifier == "Name Height"})

        nameLbl.isHidden = true
        height?.constant = 0
        /*
        if let index = chatVC.allMessages[section].firstIndex(where: {$0.textID == textMsg.textID}){
            
            if index != chatVC.allMessages[section].count - 1{
                if chatVC.allMessages[section][index + 1].uid != textMsg.uid{
                    
                    //nameLbl.isHidden = false
                    //height?.constant = 20
                    
                    if textMsg.fullname != nil{
                        nameLbl.text = textMsg.fullname
                    }
                    else if textMsg.username != nil{
                        nameLbl.text = textMsg.username
                    }
                    else{
                        //nameLbl.text = "null"
                    }
                }
                else{
                    nameLbl.isHidden = true
                    height?.constant = 0
                }
            
            }
            else{
                //nameLbl.isHidden = false
                //height?.constant = 20

                if textMsg.fullname != nil{
                    nameLbl.text = textMsg.fullname
                }
                else if textMsg.username != nil{
                    nameLbl.text = textMsg.username
                }
                else{
                    //nameLbl.text =
                }
            }
        }
        */
    }
}


extension UITableView{
    
    
    

    func setPictureCell(cell: ProductCell?, indexPath: IndexPath, product: Product, productLocation: UIViewController, shouldDownloadPic: Bool){
        
        cell?.selectionStyle = .none
        guard let userLbl = cell?.username else {
            return }
        guard let fullLbl = cell?.fullName else {
            return }
        guard let dp = cell?.userImage else {
            return }
        
        if let attr = cell?.productDescription.attributedText.mutableCopy() as? NSMutableAttributedString{
            attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
            attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: cell?.productDescription.font?.pointSize ?? 16)!], range: NSMakeRange(0, attr.length))
            cell?.productDescription.attributedText = attr
        }
        
        cell?.productDescription.text = nil
        cell?.privateBanner.isHidden = true
        cell?.imageStackBar?.isHidden = false
        cell?.commentBtn.isHidden = false
        cell?.viewFullProductView.isHidden = false
        cell?.username.text = nil
        cell?.fullName.text = nil
        cell?.fullName.attributedText = nil
        

        if let button = cell?.viewFullProductView.subviews.first as? UIButton, let productName = all.tees.first(where: {$0.productCode == product.productType})?.templateDisplayName.lowercased().capitalized{
            button.setTitle(nil, for: .normal)
            button.titleLabel?.text = nil
            
            
            button.setTitle("Buy \((productName))", for: .normal)
            button.titleLabel?.text = "Buy \(productName)"
        }

        if shouldDownloadPic{
            cell?.collectionView.reloadData()
            cell?.pageControl.currentPage = 0
        }
        
        
        (productLocation as? FullProductVC)?.isDeleted = !(product.isAvailable ?? false)
    
        cell?.commentBtn.setTitle("View 0 comments", for: .normal)
        cell?.likesLbl.text = "No likes yet"
        
        cell?.product = product
        cell?.vc = productLocation
        cell?.progressView.progress = 0.0
        cell?.title.titleLabel?.textColor = .label
        cell?.title.setTitleColor(.label, for: .normal)

        
        if !(product.isPublic ?? true){
            cell?.privateBanner.isHidden = false
            cell?.imageStackBar?.isHidden = true
            cell?.commentBtn.isHidden = true
        }
        
        if let uploadView = cell?.uploadView{
            uploadView.isHidden = true
        }
        
        if product.liked || pUserInfo.userLiked.contains(product.productID) {
            cell?.isLiked = true
        }
        else{
            cell?.isLiked = false
        }
        
        var commentCount = product.comments
        var commentString = "View \(commentCount.kmFormatted) comment"
        switch commentCount{
        case 0:
            commentString = "Add a comment"
        case 1:
            break
        default:
            if commentCount < 0{
                commentCount = 0
                commentString = "Add a comment"
            }
            else{
                commentString.append("s")
            }
        }
        cell?.commentBtn.setTitle(commentString, for: .normal)
        
        if let description = product.description, !description.isEmpty{
            cell?.productDescription?.isHidden = false
            cell?.productDescription.text = description
            cell?.productDescription.addLinks(isNotification: false, prefix: "@")
            cell?.productDescription.addLinks(isNotification: false, prefix: "#")
        }
        else{
            cell?.productDescription?.isHidden = true
        }
        
        
        if product.name != nil{
            cell?.title.titleLabel?.text = product.name
            cell?.title.setTitle(product.name, for: .normal)
        }
        
        if productLocation is FullProductVC{
            cell?.price.text = product.price?.formatPrice(addCurrency: "US")
        }
        else{
            cell?.price.text = product.price?.formatPrice()
        }

        
        
        
        checkTimes(user: product, timestampLbl: cell?.timestampLbl)
        if shouldDownloadPic{
            
            guard let nameMasks = cell?.nameMaskingViews else {
                return }
            guard let dpMasks = cell?.dpMaskingViews else {
                return }
            if cell?.nameSkeletonView.layer.mask == nil{
                cell?.nameSkeletonView.setMaskingViews(nameMasks)
                cell?.nameSkeletonView.addLayers()
            }
            if cell?.dpSkeletonView.layer.mask == nil{
                cell?.dpSkeletonView.setMaskingViews(dpMasks)
                cell?.dpSkeletonView.addLayers()
            }
            userLbl.text = nil
            dp.image = nil
            fullLbl.text = nil
            fullLbl.attributedText = nil
        }
        switch productLocation{
        case let feed as FeedVC:
            feed.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadUserInfoInFeed(feed: feed, user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell)
        case let userVC as UserVC:
            userVC.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadUserInfoInProfile(userVC: userVC, friendVC: nil, user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, userInfo: pUserInfo)
        case let friendVC as FriendVC:
            friendVC.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadUserInfoInProfile(userVC: nil, friendVC: friendVC, user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, userInfo: friendVC.friendInfo)
        case let fullVC as FullProductVC:
            cell?.viewFullProductView.isHidden = true
            fullVC.fullProduct.index = indexPath.row
            checkAndDownloadUserInfoInFullVC(user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, fullVC: fullVC)
        default:
            break
        }
    }
    
    func syncPostLikes(loadedProducts: [Product], vc: UIViewController){
        for like in likeQueue{
            if let product = loadedProducts.first(where: {$0.productID == like.key}){
                switch product.liked{
                case !like.value:
                    product.liked = like.value
                    if like.value == true{
                        product.likes += 1
                    }
                    else{
                        product.likes -= 1
                    }
                    fallthrough
                default:
                    if let cellIndex = loadedProducts.firstIndex(of: product){
                        if let cell = self.cellForRow(at: IndexPath(row: cellIndex, section: 0)) as? ProductCell{
                            cell.product = product
                            cell.isLiked = like.value
                        }
                    }
                    let otherViewControllers = (vc.tabBarController?.viewControllers ?? []).filter({$0 != vc.navigationController})
                    for viewController in otherViewControllers{
                        var vcToCheck: UIViewController! = viewController
                        if let nav = vcToCheck as? UINavigationController{
                            vcToCheck = nav.viewControllers.last
                        }
                        if vcToCheck == vc{continue}
                        guard let loadedProducts = (vcToCheck as? FriendVC)?.loadedProducts ?? (vcToCheck as? FeedVC)?.loadedProducts ?? (vcToCheck as? UserVC)?.loadedProducts ?? (vcToCheck as? ColorSectionVC)?.loadedProducts else{continue}
                        if !loadedProducts.contains(where: {$0.productID == product.productID && $0.liked != product.liked}){
                            if viewController == otherViewControllers.last{
                                likeQueue.removeValue(forKey: product.productID)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Double{
    
    func formatPrice(shortRounded: Bool = false, addCurrency: String = "", withSymbol symbol: String = "$") -> String{
        var priceAsString = "\(roundToDecimal())"
        
        if let index = priceAsString.firstIndex(of: ".")?.utf16Offset(in: priceAsString){
            switch index{
            case priceAsString.count - 1:
                priceAsString.append(contentsOf: "00")
            case priceAsString.count - 2:
                priceAsString.append(contentsOf: "0")
            default:
                break
            }
        }
        return "\(addCurrency)\(symbol)\(priceAsString)"
    }
}

extension Int {
    var kmFormatted: String {

        let doubled = Double(self)
        
        if doubled >= 10000, doubled <= 999999 {
            return String(format: "%.1fK", locale: Locale.current,doubled/1000).replacingOccurrences(of: ".0", with: "")
        }

        if doubled > 999999 {
            return String(format: "%.1fM", locale: Locale.current,doubled/1000000).replacingOccurrences(of: ".0", with: "")
        }

        return String(format: "%.0f", locale: Locale.current,doubled)
    }
}

extension Double {
    
    func roundToDecimal() -> Double {
        let f = Double(String(format: "%.2f", self)) ?? self
        return f
    }
}

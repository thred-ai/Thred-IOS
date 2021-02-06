//
//  SetUpPicMessage.swift
//  Artachat
//
//  Created by Arta Koroushnia on 2019-11-15.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import SDWebImage

extension UITableView{
    
    func setPicMessage(indexPath: IndexPath, textMsg: TextMessage, chatVC: ChatVC) -> PicMessageCell{
        
        var identifier: String!
        if textMsg.uid == pUserInfo.uid{
            identifier = "userpicmsg"
        }
        else{
            identifier = "picmsg"
        }
        let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PicMessageCell
        cell?.textMessage = textMsg

        let userImgView = cell?.userImgView
        let nameLbl = cell?.nameLbl
        guard let textImgView = cell?.textImgView else{return cell!}
        
        /*
        let nameMasks = cell?.nameMaskingViews

        if cell?.nameSkeletonView != nil{
            if cell?.nameSkeletonView.layer.mask == nil{
                cell?.nameSkeletonView.setMaskingViews(nameMasks!)
                cell?.nameSkeletonView.addLayers()
            }
        }
        */
        let dpMasks = cell?.dpMaskingViews
        
        if cell?.dpSkeletonView != nil{
            if cell?.dpSkeletonView.layer.mask == nil{
                cell?.dpSkeletonView.setMaskingViews(dpMasks!)
                cell?.dpSkeletonView.addLayers()
            }
        }
        
        textImgView.image = nil
        nameLbl?.text = nil
        userImgView?.image = nil
        
        if identifier == "picmsg"{
            self.checkAndDownloadUserInfoForTextMsg(textMsg: textMsg, nameLbl: nameLbl!, dp: userImgView!, messages: chatVC.allMessages, chatVC: chatVC, cell: cell, index: indexPath.row, section: indexPath.section)
        }
        
        self.checkAndDownloadMessageImage(msgInfo: textMsg, chatVC: chatVC, cell: cell, index: indexPath.row)
        
        return cell!
    }
}



extension UITableView{
    
    func checkAndDownloadMessageImage(msgInfo: TextMessage, chatVC: ChatVC, cell: PicMessageCell?, index: Int){
        
        var tokens = chatVC.tokens
        let picID = msgInfo.textID
        guard let msgImg = cell?.textImgView else{return}
        guard let circularProgress = cell?.circularProgress else {return}
        let aspectRatio = msgInfo.aspectRatio ?? 1.0
        
        if cell?.aspectConstraint.multiplier != aspectRatio{
            cell?.aspectConstraint.isActive = false
            cell?.aspectConstraint = msgImg.heightAnchor.constraint(equalTo: msgImg.widthAnchor, multiplier: aspectRatio)
            cell?.aspectConstraint.isActive = true
            cell?.setNeedsUpdateConstraints()
            cell?.updateConstraintsIfNeeded()
        }
        
        if let img = msgInfo.messageImg{
            circularProgress.removeFromSuperview()
            if msgImg.image != img{
                msgImg.image = img
            }
            else{
                return
            }
        }
        else{
            
            cell?.setUpCircularProgress()
            if !tokens.contains(where: {$0 == picID}){
                tokens.append(picID)
                downloadMessageImage(cell: cell, picID: picID, downloader: downloader, chatVC: chatVC){
                    tokens.removeAll(where: {$0 == picID})
                }
            }
        }
    }
    
    func downloadMessageImage(cell: PicMessageCell?, picID: String, downloader: SDWebImageDownloader?, chatVC: ChatVC, completed: @escaping () -> ()){
        
        if cell != nil{
            cell?.circularProgress.isHidden = false
            let cp = cell?.circularProgress
            let ref = Storage.storage().reference()
            ref.child("Chats/CHAT-" + chatVC.chatInfo.chatID + "/" + "Messages" + "/" + "TEXT-" + picID + ".jpg").downloadURL(completion: {[weak self] url, error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    
                    completed()
                }
                else{
                    var dub: CGFloat = 0
                    var oldDub: CGFloat = 0
                    downloader?.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                        dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                        print("Progress \(dub)")
                        print("Old Progress \(oldDub)")
                        DispatchQueue.main.sync {
                            cp?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                                oldDub = dub
                            }
                        }
                    }, completed: {[weak self] (image, data, error, finished) in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                            completed()
                        }
                        else{
                            if image != nil{
                                completed()
                                let messages = chatVC.allMessages
                                if let section = messages.firstIndex(where: {$0.contains(where: {$0.textID == picID})}){
                                    if let index = messages[section].firstIndex(where: {$0.textID == picID}){
                                        if messages.indices.contains(section){
                                            if messages[section].indices.contains(index){
                                                messages[section][index].messageImg = image
                                                if let cell = self?.cellForRow(at: IndexPath(row: index, section: section)) as? PicMessageCell{
                                                    cell.textImgView.image = image
                                                    cell.circularProgress.removeFromSuperview()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
            })
        }
        else{
            completed()
        }
    }
}

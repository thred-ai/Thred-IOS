//
//  SetUpTextMessage.swift
//  Artachat
//
//  Created by Arta Koroushnia on 2019-11-15.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit

extension UITableView{
    
    func setTextMessage(indexPath: IndexPath, textMsg: TextMessage, chatVC: ChatVC) -> TextMessageCell{
        
        var identifier: String!
        if textMsg.uid == pUserInfo.uid{
            identifier = "usertextmsg"
        }
        else{
            identifier = "textmsg"
        }
        
        let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? TextMessageCell
        let userImgView = cell?.userImgView
        let nameLbl = cell?.nameLbl
        guard let textMsgView = cell?.textMsgView
            else{
                
                return cell!}
        textMsgView.text = nil
        nameLbl?.text = nil
        userImgView?.image = nil
        cell?.textMessage = textMsg
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
        
        if identifier == "textmsg"{
            self.checkAndDownloadUserInfoForTextMsg(textMsg: textMsg, nameLbl: nameLbl!, dp: userImgView!, messages: chatVC.allMessages, chatVC: chatVC, cell: cell, index: indexPath.row, section: indexPath.section)
        }
        
        guard let message = textMsg.message else{
            
            return cell!}
        textMsgView.text = message
        cell?.checkForEmoji(text: message)
        cell?.adjustTextAlignment(text: message)

        return cell!
    }
}

extension String {
    func numberOfLines(font: UIFont, width: CGFloat) -> CGFloat {

        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height/font.lineHeight
    }
}

//
//  SetUpPictureProduct.swift
//  Thred
//
//  Created by Artak on 2019-11-01.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage


extension UITableView{
    
    func setPictureCell(indexPath: IndexPath, user: Product, productLocation: UIViewController) -> ProductCell{

        let cell = dequeueReusableCell(withIdentifier: "PictureProduct", for: indexPath) as? ProductCell
        
        cell?.selectionStyle = .none
        guard let userLbl = cell?.username else {return cell!}
        guard let fullLbl = cell?.fullName else {return cell!}
        guard let dp = cell?.userImage else {return cell!}
        guard let picID = user.picID else{return cell!}
        
        guard let nameMasks = cell?.nameMaskingViews else {return cell!}
        guard let dpMasks = cell?.dpMaskingViews else {return cell!}

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
        cell?.productDescription.text = nil
        cell?.productPicture?.image = nil
        cell?.canvasDisplayView.image = nil
        cell?.likesLbl.text = "\(0)"
        cell?.product = user
        cell?.vc = productLocation
        cell?.setGestureRecognizers()
        if user.liked{
            cell?.likeBtn.setImage(cell?.likedImage?.imageWithColor(cell?.selectedColor ?? UIColor.red), for: .normal)
        }
        else{
            cell?.likeBtn.setImage(cell?.unlikedImage, for: .normal)
        }
        
        if user.description != nil{
            cell?.productDescription.text = user.description
        }
        if user.name != nil{
            cell?.title.text = user.name
            cell?.product = user
        }
        if user.price != nil{
            
            var price = "$\(user.price ?? 0.00)"
            if price.count == 5{
                price = price + "0"
            }
            cell?.price.text = price
            
        }
        
        cell?.likesLbl.text = "\(user.likes)"
        
        
        checkTimes(user: user, timestampLbl: cell?.timestampLbl)
        switch productLocation{
        case let feed as FeedVC:
            feed.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadProductImage(user: user, vc: feed, picID: picID, cell: cell, index: indexPath.row, type: "OtherProductsPictures")
            checkAndDownloadUserInfoInFeed(feed: feed, user: user, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell)
        case let userVC as UserVC:
            userVC.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadProductImage(user: user, vc: userVC, picID: picID, cell: cell, index: indexPath.row, type: "ProductsPictures")
            checkAndDownloadUserInfoInProfile(userVC: userVC, friendVC: nil, user: user, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, userInfo: userInfo)
        case let friendVC as FriendVC:
            friendVC.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadProductImage(user: user, vc: friendVC, picID: picID, cell: cell, index: indexPath.row, type: nil)
            checkAndDownloadUserInfoInProfile(userVC: nil, friendVC: friendVC, user: user, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, userInfo: friendVC.friendInfo)
        case let fullVC as FullProductVC:
            fullVC.fullProduct.index = indexPath.row
            checkAndDownloadProductImage(user: user, vc: fullVC, picID: picID, cell: cell, index: indexPath.row, type: nil)
            checkAndDownloadUserInfoInFullVC(user: user, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, fullVC: fullVC)
        default:
            break
        }
        return cell!
    }
}

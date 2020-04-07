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

extension UITableView{
    

    func setPictureCell(indexPath: IndexPath, product: Product, productLocation: UIViewController) -> ProductCell{

        let cell = dequeueReusableCell(withIdentifier: "PictureProduct", for: indexPath) as? ProductCell
        
        cell?.selectionStyle = .none
        guard let userLbl = cell?.username else {
            
            return cell!}
        guard let fullLbl = cell?.fullName else {
            
            return cell!}
        guard let dp = cell?.userImage else {
            
            return cell!}
        guard let picID = product.picID else{
            
            return cell!}
        
        guard let nameMasks = cell?.nameMaskingViews else {
            
            return cell!}
        guard let dpMasks = cell?.dpMaskingViews else {
            
            return cell!}

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
        cell?.commentBtn.setTitle("View 0 comments", for: .normal)
        cell?.likesLbl.text = "\(0)"
        cell?.productPicture.removeShadow()
        cell?.product = product
        cell?.vc = productLocation
        cell?.setGestureRecognizers()
        
        
        if let uploadView = cell?.uploadView{
            if uploadingPosts.contains(product.productID){
                uploadView.isHidden = false
                cell?.bringSubviewToFront(uploadView)
                if let cp = cell?.uploadView.subviews.first(where: {$0.accessibilityIdentifier == "uploadSpinner"}) as? MapSpinnerView{
                    cp.animate()
                }
                cell?.isUserInteractionEnabled = false
            }
            else{
                cell?.uploadView.isHidden = true
                cell?.isUserInteractionEnabled = true
            }
        }
        
        if product.liked ?? false{
            cell?.isLiked = true
        }
        else{
            cell?.isLiked = false
        }
        
        
        if product.description != nil{
            cell?.productDescription.text = product.description
        }
        if product.name != nil{
            cell?.title.text = product.name
        }
        if product.price != nil{
            var price = "$\(product.price ?? 0.00)"
            if price.count == 5{
                price = price + "0"
            }
            cell?.price.text = price
            
        }
        
        
        cell?.likesLbl.text = "\(product.likes)"
        
        var plural = ""
        if product.comments != 1{
            plural = "s"
        }
        
        cell?.commentBtn.setTitle("View \(product.comments) comment\(plural)", for: .normal)
        
        checkTimes(user: product, timestampLbl: cell?.timestampLbl)
        switch productLocation{
        case let feed as FeedVC:
            feed.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadProductImage(user: product, vc: feed, picID: picID, cell: cell, index: indexPath.row, type: "OtherProductsPictures")
            checkAndDownloadUserInfoInFeed(feed: feed, user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell)
        case let userVC as UserVC:
            userVC.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadProductImage(user: product, vc: userVC, picID: picID, cell: cell, index: indexPath.row, type: "ProductsPictures")
            checkAndDownloadUserInfoInProfile(userVC: userVC, friendVC: nil, user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, userInfo: userInfo)
        case let friendVC as FriendVC:
            friendVC.loadedProducts[indexPath.row].index = indexPath.row
            checkAndDownloadProductImage(user: product, vc: friendVC, picID: picID, cell: cell, index: indexPath.row, type: nil)
            checkAndDownloadUserInfoInProfile(userVC: nil, friendVC: friendVC, user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, userInfo: friendVC.friendInfo)
        case let fullVC as FullProductVC:
            fullVC.fullProduct.index = indexPath.row
            checkAndDownloadProductImage(user: product, vc: fullVC, picID: picID, cell: cell, index: indexPath.row, type: nil)
            checkAndDownloadUserInfoInFullVC(user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, fullVC: fullVC)
        default:
            break
        }
        return cell!
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
                            cell.likesLbl.text = "\(product.likes)"
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

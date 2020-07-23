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
        cell?.imageStackBar.isHidden = false
        cell?.commentBtn.isHidden = false
        cell?.viewFullProductView.isHidden = false

        if shouldDownloadPic{
            cell?.collectionView.reloadData()
            cell?.pageControl.currentPage = 0
        }
        
        
        (productLocation as? FullProductVC)?.isDeleted = !(product.isAvailable ?? false)
    
        cell?.commentBtn.setTitle("Add a comment", for: .normal)
        cell?.likesLbl.text = "\(0)"
        
        cell?.product = product
        cell?.vc = productLocation
        cell?.progressView.progress = 0.0
        cell?.title.titleLabel?.textColor = .label
        cell?.title.setTitleColor(.label, for: .normal)

        
        if !(product.isPublic ?? true){
            cell?.privateBanner.isHidden = false
            cell?.imageStackBar.isHidden = true
            cell?.commentBtn.isHidden = true
        }
        
        if let uploadView = cell?.uploadView{
            if uploadingPosts.contains(product.productID){
                uploadView.isHidden = false
                cell?.bringSubviewToFront(uploadView)
                cell?.spinner.isHidden = false
                cell?.spinner.animate()
            }
            else{
                cell?.uploadView.isHidden = true
            }
        }
        
        if product.liked || userInfo.userLiked.contains(product.productID) {
            cell?.isLiked = true
        }
        else{
            cell?.isLiked = false
        }
        
        
        if product.description != nil{
            cell?.productDescription.text = product.description
            cell?.productDescription.addLinks(isNotification: false)
        }
        if product.name != nil{
            cell?.title.titleLabel?.text = product.name
            cell?.title.setTitle(product.name, for: .normal)
        }
        
        cell?.price.text = product.price?.formatPrice()

        
        cell?.likesLbl.text = "\(product.likes)"
        
        
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
            checkAndDownloadUserInfoInProfile(userVC: userVC, friendVC: nil, user: product, dp: dp, userLbl: userLbl, fullLbl: fullLbl, picCell: cell, userInfo: userInfo)
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

extension Double{
    
    func formatPrice() -> String{
        var priceAsString = "\(self.rounded(toPlaces: 2))"
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
        return "$\(priceAsString)"
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

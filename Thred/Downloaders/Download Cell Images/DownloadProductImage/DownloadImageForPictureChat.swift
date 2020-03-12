//
//  DownloadImageForPictureProduct.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SDWebImage
import FirebaseStorage

let cache = SDImageCache.shared

extension UITableView{
    func checkAndDownloadProductImage(user: Product, vc: UIViewController, picID: String, cell: ProductCell?, index: Int, type: String?){

        guard let downloader = (vc as? FeedVC)?.downloader ?? (vc as? UserVC)?.downloader ?? (vc as? FriendVC)?.downloader ?? (vc as? FullProductVC)?.downloader
            else {return}
        
        let circularProgress = cell?.circularProgress

        if let fullVC = vc as? FullProductVC{
            
            switch user.designImage {
            case .some:
                if let img = UIImage(data: user.designImage){
                    cell?.productPicture.image = img
                    cell?.circularProgress.removeFromSuperview()
                }
                else{
                    fallthrough
                }
            default:
                if let image = cache.imageFromCache(forKey: user.picID){
                    fullVC.rasterizeProductCellDisplay(cell: cell, image: image, product: user)
                }
                else{
                    downloadProductImage(pictureProduct: cell, followingUID: user.uid, picID: picID, index: index, downloader: downloader, feedVC: nil, friendVC: nil, userVC: nil, fullVC: vc as? FullProductVC, type: type, product: user){
                        return
                    }
                }
            }
        }
        else if let imgFromCache = cache.imageFromCache(forKey: picID){
            circularProgress?.removeFromSuperview()
            
            let bundlePath = Bundle.main.path(forResource: user.templateColor, ofType: "png")
            let image = UIImage(contentsOfFile: bundlePath!)
            cell?.productPicture.image = image
            cell?.productPicture.addShadowToImageNotLayer()
            cell?.canvasDisplayView.image = imgFromCache
        }
        else{
            guard var tokens = (vc as? FeedVC)?.tokens ?? (vc as? UserVC)?.tokens ?? (vc as? FriendVC)?.tokens
            else {return}
            cell?.setUpCircularProgress()
            if !tokens.contains(where: {$0 == picID}){
                tokens.append(picID)
                downloadProductImage(pictureProduct: cell, followingUID: user.uid, picID: picID, index: index, downloader: downloader, feedVC: vc as? FeedVC, friendVC: vc as? FriendVC, userVC: vc as? UserVC, fullVC: nil, type: type, product: user){
                    tokens.removeAll(where: {$0 == picID})
                }
            }
        }
    }
    
    func downloadProductImage(pictureProduct: ProductCell?, followingUID: String, picID: String, index: Int, downloader: SDWebImageDownloader?, feedVC: FeedVC?, friendVC: FriendVC?, userVC: UserVC?, fullVC: FullProductVC?, type: String?, product: Product?, completed: @escaping () -> ()){
               
        if pictureProduct != nil{
            pictureProduct?.circularProgress.isHidden = false
            let cp = pictureProduct?.circularProgress
            
            var pic_id = picID
            if product?.blurred ?? false{
                pic_id = "blur_\(pic_id)"
            }
            if fullVC == nil{
                pic_id = "thumbnail_\(picID)"
            }
            
            let ref = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + pic_id + ".png")
            ref.downloadURL(completion: { url, error in
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
                            if let imgData = data{
                                completed()
                                if fullVC != nil{
                                    cache.storeImageData(toDisk: imgData, forKey: picID)
                                    if let cell = self?.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProductCell{
                                        fullVC?.rasterizeProductCellDisplay(cell: cell, image: image, product: product)
                                    }
                                }
                                else{
                                    guard let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts else{return}
                                    if let index = products.firstIndex(where: {$0.productID == picID}){
                                        if products.indices.contains(index){
                                            cache.storeImageData(toDisk: imgData, forKey: picID)
                                            self?.setCell(index: index, image: image, templateID: product?.templateColor)
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
    
    func setCell(index: Int, image: UIImage?, templateID: String!){
        if let cell = cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
            
            let bundlePath = Bundle.main.path(forResource: templateID, ofType: "png")
            let img = UIImage(contentsOfFile: bundlePath!)
            
            
            cell.productPicture.image = img
            cell.canvasDisplayView.image = image
            cell.productPicture.addShadowToImageNotLayer()
            cell.circularProgress.removeFromSuperview()
        }
    }
    
    
}

extension UIImageView {

    func addShadowToImageNotLayer(blurSize: CGFloat = 8){

        let shadowColor = UIColor(white:0.0, alpha:0.8).cgColor

        guard let image = self.image else {return}

        let context = CGContext(data: nil,
                                width: Int(image.size.width + blurSize),
                                height: Int(image.size.height + blurSize),
                                bitsPerComponent: image.cgImage!.bitsPerComponent,
                                bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        context.setShadow(offset: CGSize(width: 0,height: 0),
                          blur: blurSize,
                          color: shadowColor)
        context.draw(image.cgImage!,
                     in: CGRect(x: 0, y: blurSize, width: image.size.width, height: image.size.height),
                     byTiling:false)

        self.image = UIImage(cgImage: context.makeImage()!)

    }
}


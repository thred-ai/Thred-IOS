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

    func downloadProductImage(pictureProduct: ProductCell?, followingUID: String, picID: String, index: Int, feedVC: FeedVC?, friendVC: FriendVC?, userVC: UserVC?, fullVC: FullProductVC?, type: String?, product: Product?, completed: @escaping (UIImage?, String?) -> ()){
               
        
        //let cp = pictureProduct?.circularProgress
        //cp?.isHidden = false

        var prefix = ""
        if product?.displaySide == "back" || product?.displaySide == "Back"{
            prefix = "BACK_"
        }
        if product == nil{
            
        }
        var thumbnail = ""
        if fullVC == nil{
            thumbnail = "thumbnail_"
        }
        let picString = "\(thumbnail)\(prefix)\(picID)"
        
        
        let ref = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + picString + ".png")
        
        ref.downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
                completed(nil, picID)
            }
            else{
                downloader.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                  
                }, completed: {(image, data, error, finished) in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        completed(nil, picString)
                    }
                    else{
                        completed(image, picString)
                    }
                })
            }
        })
    }
}

extension UIImageView {

    func addShadowToImageNotLayer(blurSize: CGFloat = 4){

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


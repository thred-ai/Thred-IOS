//
//  DownloadImageForPictureProduct.swift
//  Thred
//
//  Created by Artak on 2019-11-01.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SDWebImage

let cache = SDImageCache.shared

extension UITableView{
    func checkAndDownloadProductImage(user: Product, vc: UIViewController, picID: String, cell: ProductCell?, index: Int, type: String?){
        
        guard var tokens = (vc as? FeedVC)?.tokens ?? (vc as? UserVC)?.tokens ?? (vc as? FriendVC)?.tokens
            else {return}
        guard let downloader = (vc as? FeedVC)?.downloader ?? (vc as? UserVC)?.downloader ?? (vc as? FriendVC)?.downloader
            else {return}
        
        let circularProgress = cell?.circularProgress

        if let imgFromCache = cache.imageFromCache(forKey: picID){
            circularProgress?.removeFromSuperview()
            cell?.productPicture.image = imgFromCache
        }
        else{
            cell?.setUpCircularProgress()
            if !tokens.contains(where: {$0 == picID}){
                tokens.append(picID)
                
                downloadProductImage(pictureproduct: cell, followingUID: user.uid, picID: picID, index: index, downloader: downloader, feedVC: vc as? FeedVC, friendVC: vc as? FriendVC, userVC: vc as? UserVC, type: type){
                    tokens.removeAll(where: {$0 == picID})
                }
            }
        }
    }
    
    func downloadProductImage(pictureproduct: ProductCell?, followingUID: String, picID: String, index: Int, downloader: SDWebImageDownloader?, feedVC: FeedVC?, friendVC: FriendVC?, userVC: UserVC?, type: String?, completed: @escaping () -> ()){
               
        if pictureproduct != nil{
            pictureproduct?.circularProgress.isHidden = false
            let cp = pictureproduct?.circularProgress
            let ref: StorageReference? = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + picID + ".jpg")
            ref?.downloadURL(completion: { url, error in
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
                                guard let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts else{return}
                                if let index = products.firstIndex(where: {$0.productID == picID}){
                                    if products.indices.contains(index){
                                        cache.storeImageData(toDisk: imgData, forKey: picID)
                                        self?.setCell(index: index, image: image)
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
    
    func setCell(index: Int, image: UIImage?){
        if let cell = cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
            cell.productPicture.image = image
            cell.circularProgress.removeFromSuperview()
        }
    }
}


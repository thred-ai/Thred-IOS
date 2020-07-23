//
//  ExploreColorCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-26.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import FirebaseFirestore

class ExploreColorCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var colorIcon: UIView!
    @IBOutlet weak var colorNameLbl: UILabel!
    
    var collectionViewOffset: CGFloat {
        get {
            return collectionView.contentOffset.x
        }

        set {
            collectionView.contentOffset.x = newValue
        }
    }
    
    var postArray: [Product]!
    var templateColor: String?
    weak var exploreVC: ExploreViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.register(UINib(nibName: "ExploreProductCell", bundle: nil), forCellWithReuseIdentifier: "ExploreProductCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Initialization code
    }
    
    
    
    func getProducts(completed: @escaping ()->()){
        
        if postArray == nil{
            guard let userUID = userInfo.uid else{completed(); return}
            postArray = [Product]()
            
            let color = templateColor
            Firestore.firestore().collectionGroup("Products").whereField("Template_Color", isEqualTo: templateColor ?? "").whereField("Has_Picture", isEqualTo: true).whereField("Blurred", isEqualTo: false).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Timestamp", descending: true).limit(to: 8).getDocuments(completion: { snaps, err in
                if err != nil{
                    completed()
                    print(err?.localizedDescription ?? "")
                }
                else{
                    
                    for (index, snap) in (snaps?.documents ?? []).enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
                        let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                        let uid = snap["UID"] as! String
                        let description = snap["Description"] as? String
                        let name = snap["Name"] as? String
                        let blurred = snap["Blurred"] as? Bool
                        let templateColor = snap["Template_Color"] as? String
                        guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                        let likes = snap["Likes"] as? Int
                        let comments = ((snap["Comments"]) as? Int) ?? 0
                        let productType = snap["Type"] as? String ?? defaultProductType

                        if userInfo.usersBlocking.contains(uid){
                            continue
                        }
                        let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true, productType: productType)
                        
                        Firestore.firestore().collection("Users").document(uid).collection("Products").document(product.productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                        
                            if error != nil{
                                print(error?.localizedDescription ?? "")
                            }
                            else{
                                userInfo.userLiked.removeAll(where: {$0 == product.productID})
                                if let likeDocs = snapLikes?.documents{
                                    if likeDocs.isEmpty{
                                        product.liked = false
                                    }
                                    else{
                                        product.liked = true
                                        if !(userInfo.userLiked.contains(product.productID)){
                                            userInfo.userLiked.append(product.productID)
                                        }
                                    }
                                }
                                else{
                                    product.liked = false
                                }
                            }
                            
                            if self.templateColor == color{
                                
                                self.postArray?.append(product)
                                if self.postArray.count == snaps?.documents.count ?? 0{
                                    
                                    self.postArray?.sort(by: {$0.likes > $1.likes})
                                    if let colorIndex = self.exploreVC?.colorSections.firstIndex(where: {$0["ID"] as? String == self.templateColor}){
                                        
                                        var downloading = self.exploreVC?.colorSections[colorIndex]["Color_Downloading"] as? [String]
                                        downloading?.removeAll(where: {$0 == color})
                                        self.exploreVC?.colorSections[colorIndex]["Array"] = self.postArray
                                    }
                                    completed()
                                }
                            }
                        })
                    }
                }
            })
        }
        else{
            completed()
        }
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = postArray[indexPath.item]
        DispatchQueue.main.async {
            self.exploreVC?.productToOpen = product
            self.exploreVC?.performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreProductCell", for: indexPath) as? ExploreProductCell
        
        cell?.imageView.image = nil
        cell?.circularProgress.isHidden = false
        
        guard postArray?.indices.contains(indexPath.item) ?? false, let product = postArray?[indexPath.item] else{return cell!}
        
        cell?.contentView.backgroundColor = UIColor(named: product.templateColor)

        DispatchQueue(label: "cache").sync {
            if let image = cache.imageFromCache(forKey: "thumbnail_\(product.picID ?? "")"){
                DispatchQueue.main.async {
                    if let index = self.postArray?.firstIndex(where: {$0.productID == product.productID}){
                        print(index)
                        print(product.templateColor!)
                        if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ExploreProductCell{
                            cell.imageView.image = image
                            cell.circularProgress.isHidden = true
                        }
                        else{
                            collectionView.performBatchUpdates({
                                collectionView.reloadItems(at: [indexPath])
                            }, completion: nil)
                        }
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    self.downloadProductCellImage(indexPath: indexPath, cell: cell, product: product)
                }
            }
        }
        return cell!
    }
    
    
    
    
    func downloadProductCellImage(indexPath: IndexPath, cell: ExploreProductCell?, product: Product){
                
        
        if let colorIndex = self.exploreVC?.colorSections.firstIndex(where: {$0["ID"] as? String == product.templateColor}){
            
            var downloading = self.exploreVC?.colorSections[colorIndex]["Downloading"] as? [String]
            
            if !(downloading?.contains(product.picID ?? "null") ?? true){
                
                cell?.circularProgress.isHidden = false
                downloading?.append(product.picID ?? "null")
                self.collectionView.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: product.userInfo.uid ?? "", picID: product.picID ?? "", index: indexPath.item, product: product, isThumbnail: true){ image in
                    
                    guard let products = self.exploreVC?.colorSections else{
                        return}
                        if let index = products.firstIndex(where: {$0["ID"] as? String == product.templateColor}){
                            if products.indices.contains(index){
                                
                                if var downloading = self.exploreVC?.colorSections[index]["Downloading"] as? [String]{
                                    if let postIndex = downloading.firstIndex(of: product.productID){
                                        downloading.remove(at: postIndex)
                                        
                                    }
                                }
                                if self.templateColor == (products[index]["ID"] as? String){
                                    if let index = self.postArray?.firstIndex(where: {$0.productID == product.productID}), let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ExploreProductCell{
                                        cell.imageView.image = image
                                        cell.circularProgress.isHidden = true
                                    }
                                }
                            }
                        }
                    
                }
            }
            else{
                
            }
        }
        else{
            
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        colorIcon.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    override func layoutSubviews() {
        colorIcon.layer.cornerRadius = colorIcon.frame.height / 2
        colorIcon.clipsToBounds = true
        colorIcon.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        colorIcon.layer.borderWidth = colorIcon.frame.height / 17.75
        colorIcon.setRadiusWithShadow()
        
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension UICollectionView{
    func downloadExploreProductImage(circularProgress: CircularProgress?, followingUID: String, picID: String, index: Int, product: Product?, isThumbnail: Bool, completed: @escaping (UIImage?) -> ()){
        circularProgress?.isHidden = false
        var pic_id = picID
            
        if isThumbnail{
            pic_id = "thumbnail_\(picID)"
        }
        let ref = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + pic_id + ".png")
        
        ref.downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
                completed(nil)
            }
            else{
                var dub: CGFloat = 0
                var oldDub: CGFloat = 0
                downloader.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages, .avoidDecodeImage], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                    dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                    print("Progress \(dub)")
                    print("Old Progress \(oldDub)")
                    DispatchQueue.main.async {
                        circularProgress?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                            oldDub = dub
                        }
                    }
                }, completed: { (image, data, error, finished) in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        completed(nil)
                    }
                    else{
                        if isThumbnail{
                            cache.storeImage(toMemory: image, forKey: "thumbnail_\(picID)")
                        }
                        else{
                            cache.storeImage(toMemory: image, forKey: "\(picID)")
                        }
                        completed(image)
                    }
                })
            }
        })
    }
    
    
    func downloadThredListImage(isThumbnail: Bool, cell: PhotosCell?, followingUID: String, picID: String, completed: @escaping (UIImage?) -> ()){
        
            //cell?.circularProgress.isHidden = false
            //let cp = pictureProduct?.circularProgress
            var pic_id = picID
            //if product?.blurred ?? false{
               // pic_id = "blur_\(pic_id)"
            //}
            
            if isThumbnail{
                pic_id = "thumbnail_\(picID)"
            }
            
            let ref = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + pic_id + ".png")
            ref.downloadURL(completion: { url, error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    completed(nil)
                }
                else{
                    //var dub: CGFloat = 0
                    //var oldDub: CGFloat = 0
                    downloader.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages, .avoidDecodeImage], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                        //dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                       // DispatchQueue.main.async {
                            //cp?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                                //oldDub = dub
                            //}
                        //}
                    }, completed: { (image, data, error, finished) in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                            completed(nil)
                        }
                        else{
                            completed(image)
                        }
                    })
                }
            })
    }
}

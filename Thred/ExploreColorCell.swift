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
    @IBOutlet weak var numPostsLbl: UILabel!
    
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
            guard let userUID = pUserInfo.uid else{completed(); return}
            postArray = [Product]()
            let tag = templateColor ?? ""
            
            Firestore.firestore().collectionGroup("Products").whereField("Tags", arrayContains: templateColor ?? "").whereField("Has_Picture", isEqualTo: true).whereField("Blurred", isEqualTo: false).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Timestamp", descending: true).limit(to: 8).getDocuments(completion: { snaps, err in
                if err != nil{
                    completed()
                    print(err?.localizedDescription ?? "")
                }
                else{
                    var removed = 0
                    for (index, snap) in (snaps?.documents ?? []).enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
                        let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                        let uid = snap["UID"] as! String
                        let description = snap["Description"] as? String
                        let name = snap["Name"] as? String
                        let blurred = snap["Blurred"] as? Bool
                        let templateColor = snap["Template_Color"] as? String
                        guard let priceCents = (snap["Price_Cents"] as? Double)
                        else{
                            removed += 1
                            continue
                        }
                        let likes = snap["Likes"] as? Int
                        let comments = ((snap["Comments"]) as? Int) ?? 0
                        let productType = snap["Type"] as? String ?? defaultProductType
                        let displaySide = snap["Side"] as? String ?? "front"
                        let matchTag = (snap["Tags"] as? [String])?.first(where: {$0 == tag})
                        let sides = snap["Sides"] as? [String] ?? ["Front"]

                        if pUserInfo.usersBlocking.contains(uid){
                            removed += 1
                            continue
                        }
                        let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: pUserInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true, productType: productType, displaySide: displaySide, supportedSides: sides)
                        
                        Firestore.firestore().collection("Users").document(uid).collection("Products").document(product.productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                        
                            if error != nil{
                                print(error?.localizedDescription ?? "")
                            }
                            else{
                                pUserInfo.userLiked.removeAll(where: {$0 == product.productID})
                                if let likeDocs = snapLikes?.documents{
                                    if likeDocs.isEmpty{
                                        product.liked = false
                                    }
                                    else{
                                        product.liked = true
                                        if !(pUserInfo.userLiked.contains(product.productID)){
                                            pUserInfo.userLiked.append(product.productID)
                                        }
                                    }
                                }
                                else{
                                    product.liked = false
                                }
                            }
                            
                            if self.templateColor == tag{
                                
                                self.postArray?.append(product)
                                if self.postArray.count == (snaps?.documents.count ?? 0) - removed{
                                    
                                    self.postArray?.sort(by: {$0.likes > $1.likes})
                                    if let colorIndex = self.exploreVC?.hashTags.firstIndex(where: {$0.display == matchTag}){
                                        
                                        var downloading = self.exploreVC?.hashTags[colorIndex].tagDownloading
                                        downloading?.removeAll(where: {$0 == tag})
                                        self.exploreVC?.hashTags[colorIndex].array = self.postArray
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
        guard postArray.indices.contains(indexPath.item) else{return cell!}
        let product = postArray[indexPath.item]
        cell?.product = product
        guard let array = postArray else{return cell!}
        guard let temp = templateColor else{return cell!}
        
        cell?.contentView.backgroundColor = UIColor(named: "ProductColor")

        
        let type = all.tees.first(where: {$0.productCode == product.productType})
        cell?.addConstraints(template: type)
        
        var prefix = ""
        if product.displaySide == "back" || product.displaySide == "Back"{
            prefix = "BACK_"
        }

        DispatchQueue(label: "cache").sync {
            if let image = cache.imageFromCache(forKey: "thumbnail_\(prefix)\(product.picID ?? "")"), let color = all.tees.first(where: {$0.productCode == product.productType})?.colors?.first(where: {$0.code == product.templateColor}){
                DispatchQueue.main.async {
                    if let index = array.firstIndex(where: {$0.productID == product.productID}){
                        print(index)
                        var data: Data!
                        
                        if product.displaySide == "back" || product.displaySide == "Back"{
                            data = color.imgBack
                        }
                        else{
                            data = color.img
                        }
                        let img = UIImage(data: data)
                        for view in cell?.canvasDisplayViews ?? []{
                            view.imageView?.image = image
                            view.setImage(image, for: .normal)
                        }
                        cell?.imageView.image = img
                        cell?.circularProgress.isHidden = true
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    self.downloadProductCellImage(indexPath: indexPath, cell: cell, product: product, temp: temp, array: array, collectionView: collectionView)
                }
            }
        }
        return cell!
    }
    
    
    
    
    func downloadProductCellImage(indexPath: IndexPath, cell: ExploreProductCell?, product: Product, temp: String, array: [Product], collectionView: UICollectionView?){
                
        guard let vc = exploreVC else{return}
        if let colorIndex = vc.hashTags.firstIndex(where: {($0.array?.contains(where: {$0.productID == product.productID}) ?? true) as Bool}){
            
            var downloading = vc.hashTags[colorIndex].downloading
            
            if !(downloading?.contains(product.picID ?? "null") ?? true){
                
                cell?.circularProgress.isHidden = false
                downloading?.append(product.picID ?? "null")
                
                UIApplication.shared.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: product.userInfo.uid ?? "", picID: product.picID ?? "", index: indexPath.item, product: product, isThumbnail: true){ image in
                    
                    let products = vc.hashTags
                    if let index = vc.hashTags.firstIndex(where: {($0.array?.contains(where: {$0.productID == product.productID}) ?? true) as Bool}){
                        if products.indices.contains(index){
                            if var downloading = vc.hashTags[index].downloading{
                                if let postIndex = downloading.firstIndex(of: product.productID){
                                    downloading.remove(at: postIndex)
                                }
                            }
                            if let index = self.postArray?.firstIndex(where: {$0.productID == product.productID}){
                                if collectionView?.numberOfItems(inSection: 0) == array.count{
                                    collectionView?.performBatchUpdates({
                                        collectionView?.reloadItems(at: [IndexPath(item: index, section: 0)])
                                    }, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
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
        
        numPostsLbl.superview?.layer.cornerRadius = 2
        numPostsLbl.superview?.clipsToBounds = true
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension UIApplication{
    func downloadExploreProductImage(circularProgress: CircularProgress?, followingUID: String, picID: String, index: Int, product: Product?, isThumbnail: Bool, completed: @escaping (UIImage?) -> ()){
        circularProgress?.isHidden = false
            
        var prefix = ""
        if product?.displaySide == "back" || product?.displaySide == "Back"{
            prefix = "BACK_"
        }
        
        var thumbnail = ""
        if isThumbnail{
            thumbnail = "thumbnail_"
        }
        
        let picString = "\(thumbnail)\(prefix)\(picID)"
        
        let ref = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + picString + ".png")
        
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
                        
                        cache.storeImage(toMemory: image, forKey: picString)
                        completed(image)
                    }
                })
            }
        })
    }
}

extension UICollectionView{
    func downloadThredListImage(isThumbnail: Bool, cell: PhotosCell?, followingUID: String, picID: String, displaySide: String, completed: @escaping (UIImage?) -> ()){

        var prefix = ""
        if displaySide == "back" || displaySide == "Back"{
            prefix = "BACK_"
        }
        
        var thumbnail = ""
        if isThumbnail{
            thumbnail = "thumbnail_"
        }
        
        let picString = "\(thumbnail)\(prefix)\(picID)"

        let ref = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + picString + ".png")
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

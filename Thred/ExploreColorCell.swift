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

class ExploreColorCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var colorIcon: UIView!
    
    var postArray: [Product]!
    var templateColor: String?
    weak var downloader: SDWebImageDownloader?
    weak var exploreVC: ExploreViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "ExploreProductCell", bundle: nil), forCellWithReuseIdentifier: "ExploreProductCell")
            
            
        // Initialization code
    }
    
    func getProducts(){
        
        if postArray == nil{
            postArray = [Product]()
            Firestore.firestore().collectionGroup("Products").whereField("Timestamp", isLessThanOrEqualTo: Date()).order(by: "Timestamp", descending: true).whereField("Template_Color", isEqualTo: templateColor ?? "").order(by: "Likes", descending: false).limit(to: 8).getDocuments(completion: { snaps, err in
                if err != nil{
                    print(err?.localizedDescription ?? "")
                }
                else{
                    for (index, doc) in (snaps?.documents ?? []).enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
                        let timestamp = (doc["Timestamp"] as? Timestamp)?.dateValue()
                        let uid = doc["UID"] as! String
                        let description = doc["Description"] as? String
                        let name = doc["Name"] as? String
                        let blurred = doc["Blurred"] as? Bool
                        let templateColor = doc["Template_Color"] as? String
                        guard let priceCents = (doc["Price_Cents"] as? Double) else{return}
                        let likes = doc["Likes"] as? Int

                        self.postArray.append(Product(uid: uid, picID: doc.documentID, description: description, fullName: nil, username: nil, productID: doc.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, fromCache: false, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes))
                    }
                    self.postArray.sort(by: {$0.likes > $1.likes})
                    if let colorIndex = self.exploreVC?.colorSections.firstIndex(where: {$0.keys.first == self.templateColor}){
                        
                        self.exploreVC?.colorSections[colorIndex] = [self.templateColor ?? "" : self.postArray]
                    }
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            })
        }
        else{
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreProductCell", for: indexPath) as? ExploreProductCell
        
        cell?.imageView.image = nil
        cell?.circularProgress.isHidden = false
        cell?.contentView.backgroundColor = UIColor(named: postArray[indexPath.item].templateColor)

        if let image = cache.imageFromMemoryCache(forKey: postArray[indexPath.item].picID){
            cell?.imageView.image = image
            cell?.circularProgress.isHidden = true
        }
        else{
            cell?.circularProgress.isHidden = false
            self.downloadExploreProductImage(pictureProduct: cell, followingUID: postArray[indexPath.item].uid, picID: postArray[indexPath.item].picID ?? "", index: indexPath.item, exploreVC: exploreVC, product: postArray[indexPath.item]){
                if self.postArray.indices.contains(indexPath.item){
                    collectionView.performBatchUpdates({
                        collectionView.reloadItems(at: [indexPath])
                    }, completion: nil)
                }
            }
        }
        
        return cell!
    }
    
    
    
    func downloadExploreProductImage(pictureProduct: ExploreProductCell?, followingUID: String, picID: String, index: Int, exploreVC: ExploreViewController?, product: Product?, completed: @escaping () -> ()){
               
        if pictureProduct != nil{
            pictureProduct?.circularProgress.isHidden = false
            let cp = pictureProduct?.circularProgress
            
            var pic_id = picID
            if product?.blurred ?? false{
                pic_id = "blur_\(pic_id)"
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
                    self.downloader?.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages, .avoidDecodeImage], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                        dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                        print("Progress \(dub)")
                        print("Old Progress \(oldDub)")
                        DispatchQueue.main.sync {
                            cp?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                                oldDub = dub
                            }
                        }
                    }, completed: { (image, data, error, finished) in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                            completed()
                        }
                        else{
                            completed()
                            guard let products = exploreVC?.colorSections else{return}
                            if let index = products.firstIndex(where: {$0.keys.first == product?.templateColor}){
                                if products.indices.contains(index){
                                    if let array = products[index][product!.templateColor]{
                                        if let arrayIndex = array?.firstIndex(where: {$0.picID == product?.picID}){
                                            if array?.indices.contains(arrayIndex) ?? false{
                                                cache.storeImage(toMemory: image, forKey: picID)
                                                completed()
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
    
    func downloadImage(){
        //downloader.down
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

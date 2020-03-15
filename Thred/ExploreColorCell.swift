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
    weak var downloader: SDWebImageDownloader?
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
            postArray = [Product]()
            let color = templateColor
            Firestore.firestore().collectionGroup("Products").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).order(by: "Timestamp", descending: true).whereField("Template_Color", isEqualTo: templateColor ?? "").order(by: "Likes", descending: false).limit(to: 8).getDocuments(completion: { snaps, err in
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

                        if self.templateColor == color{
                            self.postArray?.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, fromCache: false, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked?.contains(snap.documentID), designImage: nil))
                        }
                    }
                    self.postArray?.sort(by: {$0.likes > $1.likes})
                    self.postArray = self.postArray.removeDuplicates()
                    if let colorIndex = self.exploreVC?.colorSections.firstIndex(where: {$0["ID"] as? String == self.templateColor}){
                        self.exploreVC?.colorSections[colorIndex]["Array"] = self.postArray
                    }
                    completed()
                }
            })
        }
        else{
            completed()
        }
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = postArray[indexPath.row]
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
        cell?.contentView.backgroundColor = UIColor(named: self.postArray[indexPath.item].templateColor)

        if let image = cache.imageFromCache(forKey: self.postArray[indexPath.item].picID){
            cell?.imageView.image = image
            cell?.circularProgress.isHidden = true
            print(image.size.height / image.size.width)
        }
        else{
            self.downloadProductCellImage(indexPath: indexPath, cell: cell)
        }
        return cell!
    }
    
    
    
    
    func downloadProductCellImage(indexPath: IndexPath, cell: ExploreProductCell?){
        if let colorIndex = self.exploreVC?.colorSections.firstIndex(where: {$0["ID"] as? String == self.templateColor}){
            
            var downloading = self.exploreVC?.colorSections[colorIndex]["Downloading"] as? [String]
            if !(downloading?.contains(self.postArray[indexPath.item].picID ?? "null") ?? true){
                cell?.circularProgress.isHidden = false
                downloading?.append(self.postArray[indexPath.item].picID ?? "null")
                self.collectionView.downloadExploreProductImage(pictureProduct: cell, followingUID: self.postArray[indexPath.item].uid, picID: self.postArray[indexPath.item].picID ?? "", index: indexPath.item, product: self.postArray[indexPath.item], downloader: downloader){
                    
                    guard let products = self.exploreVC?.colorSections else{
                        return}
                    if self.postArray.indices.contains(indexPath.item){
                        if let index = products.firstIndex(where: {$0["ID"] as? String == self.postArray[indexPath.item].templateColor}){
                            if products.indices.contains(index){
                                
                                if var downloading = self.exploreVC?.colorSections[index]["Downloading"] as? [String]{
                                    if let postIndex = downloading.firstIndex(of: self.postArray[indexPath.item].productID){
                                        downloading.remove(at: postIndex)
                                        
                                    }
                                }
                                
                                if let array = products[index]["Array"] as? [Product]{
                                    if let arrayIndex = array.firstIndex(where: {$0.picID == self.postArray[indexPath.item].picID}){
                                        if array.indices.contains(arrayIndex){
                                            if self.postArray.indices.contains(indexPath.item){
                                                if cell != nil{
                                                    if self.collectionView.numberOfItems(inSection: 0) > 0{
                                                        self.collectionView.performBatchUpdates({
                                                            self.collectionView.reloadItems(at: [indexPath])
                                                        }, completion: nil)
                                                    }
                                                }
                                            }
                                        }
                                    }
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
        self.postArray.removeAll()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
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
    func downloadExploreProductImage(pictureProduct: ExploreProductCell?, followingUID: String, picID: String, index: Int, product: Product?, downloader: SDWebImageDownloader?, completed: @escaping () -> ()){
               
        if pictureProduct != nil{
            pictureProduct?.circularProgress.isHidden = false
            let cp = pictureProduct?.circularProgress
            
            var pic_id = picID
            if product?.blurred ?? false{
                pic_id = "blur_\(pic_id)"
            }
            
            let ref = Storage.storage().reference().child("Users/" + followingUID + "/" + "Products/" + picID + "/" + "thumbnail_" + pic_id + ".png")
            ref.downloadURL(completion: { url, error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    completed()
                }
                else{
                    var dub: CGFloat = 0
                    var oldDub: CGFloat = 0
                    downloader?.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages, .avoidDecodeImage], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                        dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                        print("Progress \(dub)")
                        print("Old Progress \(oldDub)")
                        DispatchQueue.main.async {
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
                            cache.storeImage(toMemory: image, forKey: picID)
                            completed()
                        }
                    })
                }
            })
        }
        else{
            completed()
        }
    }
}

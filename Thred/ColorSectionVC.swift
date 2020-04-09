//
//  ColorSectionVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import FirebaseFirestore
import SDWebImage

class ColorSectionVC: UICollectionViewController {

    private let reuseIdentifier = "ColorSectionCell"
    var loadedProducts = [Product]()
    var tokens = [String]()
    var downloader: SDWebImageDownloader? = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
    var templateColor = String()

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // Do any additional setup after loading the view.
        
        collectionView.register(UINib(nibName: "ExploreProductCell", bundle: nil), forCellWithReuseIdentifier: "ExploreProductCell")
        
        if !isLoading{
            isLoading = true
            getProducts(fromInterval: nil) {
                self.isLoading = false
            }
        }
    }
    var query: Query! = nil
    var isLoading = false
    
    override func viewWillAppear(_ animated: Bool) {
        self.showCenterBtn()
        if downloader == nil{
            downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
    }
    
    var last: DocumentSnapshot!

    func getProducts(fromInterval: Int?, completed: @escaping ()->()){
        
        if fromInterval == nil{
            query = Firestore.firestore().collectionGroup("Products").whereField("Template_Color", isEqualTo: templateColor).whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).order(by: "Likes", descending: true).limit(to: 12)
        }
        else if last != nil{
            query = Firestore.firestore().collectionGroup("Products").whereField("Template_Color", isEqualTo: templateColor).whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).order(by: "Likes", descending: true).start(afterDocument: last).limit(to: 12)
        }
        
        guard let userUID = userInfo.uid else{return}
        checkAuthStatus {
            self.refreshLists(userUID: userUID){
                self.query.getDocuments(completion: { snaps, err in
                    if err != nil{
                        completed()
                        print(err?.localizedDescription ?? "")
                    }
                    else{
                        if let docs = snaps?.documents, !docs.isEmpty{
                            for (index, snap) in docs.enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
                                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                                let uid = snap["UID"] as! String
                                
                                if userInfo.usersBlocking.contains(uid){
                                    continue
                                }
                                
                                let description = snap["Description"] as? String
                                let name = snap["Name"] as? String
                                let blurred = snap["Blurred"] as? Bool
                                let templateColor = snap["Template_Color"] as? String
                                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                                let likes = snap["Likes"] as? Int
                                let comments = ((snap["Comments"]) as? Int) ?? 0

                                self.loadedProducts.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments))
                                
                                self.collectionView.performBatchUpdates({
                                    self.collectionView.insertItems(at: [IndexPath(item: self.loadedProducts.count - 1, section: 0)])
                                }, completion: { finished in
                                    if finished{
                                        if snap == docs.last{
                                            self.last = docs.last
                                            completed()
                                        }
                                    }
                                })
                            }
                        }
                        else{
                            completed()
                        }
                    }
                })
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height){
            print("fromScroll")
            if let last = loadedProducts.last{
                let interval = last.likes
                if !isLoading{
                    isLoading = true
                    getProducts(fromInterval: interval){
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    var productToOpen: Product!
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = loadedProducts[indexPath.row]
        DispatchQueue.main.async {
            self.productToOpen = product
            self.performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        downloader?.invalidateSessionAndCancel(true)
        downloader = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if loadedProducts.count > 8{
            for product in loadedProducts.suffix(loadedProducts.count - 8){
                cache.removeImageFromMemory(forKey: product.picID)
            }
        }
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return loadedProducts.count
    }
    

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreProductCell", for: indexPath) as? ExploreProductCell
        
        
        cell?.imageView.image = nil
        cell?.circularProgress.isHidden = false
        cell?.contentView.backgroundColor = .clear
        cell?.contentView.backgroundColor = UIColor(named: self.loadedProducts[indexPath.item].templateColor)

        if let image = cache.imageFromCache(forKey: "thumbnail_\(self.loadedProducts[indexPath.item].picID ?? "")"){
            cell?.imageView.image = image
            cell?.circularProgress.isHidden = true
            print(image.size.height / image.size.width)
        }
        else{
                
            if !(tokens.contains(loadedProducts[indexPath.item].picID ?? "null")){
                    cell?.circularProgress.isHidden = false
                    tokens.append(loadedProducts[indexPath.item].picID ?? "null")
                self.collectionView.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: self.loadedProducts[indexPath.item].uid, picID: self.loadedProducts[indexPath.item].picID ?? "", index: indexPath.item, product: self.loadedProducts[indexPath.item], downloader: downloader, isThumbnail: true){
                        
                        self.tokens.removeAll(where: {$0 == self.loadedProducts[indexPath.item].picID})
                        
                        if self.loadedProducts.indices.contains(indexPath.item){
                            
                            if cell != nil{
                                if collectionView.numberOfItems(inSection: 0) > 0{
                                    collectionView.performBatchUpdates({
                                        collectionView.reloadItems(at: [indexPath])
                                    }, completion: nil)
                                }
                            }
                        }
                    }
                }
            
        }
        return cell!
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

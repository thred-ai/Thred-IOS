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
    }
    
    var last: DocumentSnapshot!

    func getProducts(fromInterval: Int?, completed: @escaping ()->()){
        
        if fromInterval == nil{
            query = Firestore.firestore().collectionGroup("Products").whereField("Template_Color", isEqualTo: templateColor).whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Likes", descending: true).limit(to: 36)
        }
        else if last != nil{
            query = Firestore.firestore().collectionGroup("Products").whereField("Template_Color", isEqualTo: templateColor).whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Likes", descending: true).start(afterDocument: last).limit(to: 36)
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
                            var counter = 0
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

                                let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true)

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
                                    
                                    self.loadedProducts.append(product)
                                    counter += 1
                                    if counter == docs.count{
                                        self.last = docs.last
                                        self.collectionView.reloadData()
                                        completed()
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) / 2{
            print("fromScroll")
            if let last = loadedProducts.last{
                let interval = last.likes
                if !isLoading, canLoadMore{
                    isLoading = true
                    getProducts(fromInterval: interval){
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    var canLoadMore = false
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 0 {
            canLoadMore = false
            // swipes from top to bottom of screen -> down
        } else {
            canLoadMore = true
            // swipes from bottom to top of screen -> up
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
        guard self.loadedProducts.indices.contains(indexPath.item) else {
            
            return cell!}
        let product = self.loadedProducts[indexPath.item]

        if let image = cache.imageFromCache(forKey: "thumbnail_\(product.picID ?? "")"){
            if let index = self.loadedProducts.firstIndex(where: {$0.productID == product.productID}), let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ExploreProductCell{
                cell.imageView.image = image
                cell.circularProgress.isHidden = true
                print(image.size.height / image.size.width)
            }
            else{
                cell?.imageView.image = image
                cell?.circularProgress.isHidden = true
            }
        }
        else{
                
            if !(tokens.contains(product.picID ?? "null")){
                    cell?.circularProgress.isHidden = false
                    tokens.append(product.picID ?? "null")
                self.collectionView.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: product.userInfo.uid ?? "", picID: product.picID ?? "", index: indexPath.item, product: product, isThumbnail: true){ image in
                        
                    self.tokens.removeAll(where: {$0 == self.loadedProducts[indexPath.item].picID})
                        
                    if let index = self.loadedProducts.firstIndex(where: {$0.productID == product.productID}), let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ExploreProductCell{
                        cell.imageView.image = image
                        cell.circularProgress.isHidden = true
                    }
                    else{
                        cell?.imageView.image = image
                        cell?.circularProgress.isHidden = true
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
    '
    }
    */

}

extension UIViewController{
    
    
}

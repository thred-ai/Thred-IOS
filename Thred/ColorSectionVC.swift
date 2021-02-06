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
    
    var hashtag: Hashtag?
        
    var templateColor: String?{
        return hashtag?.display
    }
    
    var numPosts: Int?{
        return hashtag?.postsCount
    }
    
    
    func getHashtagBackgroundInfo(completed: @escaping (Bool) -> ()){
        guard numPosts == nil else{completed(true); return}
        Firestore.firestore().collection("Tags").document(templateColor ?? "").getDocument(completion: { doc, error in
            if error != nil{
                completed(false)
                print(error?.localizedDescription ?? "")
            }
            else{
                if let doc = doc, doc.exists, let postCount = doc["Posts_Count"] as? Int, postCount > 0{
                    self.hashtag = Hashtag(postsCount: postCount, array: nil, display: doc.documentID, offset: 0, downloading: [], tagDownloading: [], blurred: false, topPost: nil)
                    completed(true)
                }
                else{
                    completed(false)
                }
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // Do any additional setup after loading the view.
        
        collectionView.register(UINib(nibName: "ExploreProductCell", bundle: nil), forCellWithReuseIdentifier: "ExploreProductCell")

        
        
        
        getHashtagBackgroundInfo(completed: { finished in
            self.hashtagExists = finished
            self.isLoadingHashtag = false
            self.collectionView.reloadData()
        })
        if !isLoading{
            isLoading = true
            getProducts(fromInterval: nil) {
                self.isLoading = false
            }
        }
    }
    var query: Query! = nil
    var isLoading = false
    var isLoadingHashtag = true
    
    var hashtagExists: Bool!
    
    override func viewWillAppear(_ animated: Bool) {
        hideCenterBtn()
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "hashtagHeader", for: indexPath) as? HashtagHeaderView
        guard let tag = templateColor else{return view!}
        
        view?.hashtagLbl.text = nil
        view?.featuredLbl.text = nil
        view?.featuredLbl.attributedText = nil
        view?.featuredLbl.removeShadow()
        view?.hashtagLbl?.removeShadow()
        view?.hashtagLbl?.text = "#\(tag)"
        view?.hashtagLbl?.setRadiusWithShadow()
        view?.viewFullProductView.isHidden = true
        view?.viewFullProductView.removeShadow()
        view?.numPostsLbl.text = " "
        view?.numPostsLbl?.removeShadow()
        view?.featuredLbl.setRadiusWithShadow()
        view?.viewFullProductView.setRadiusWithShadow()
        guard let button = view?.viewFullProductView.subviews.first as? UIButton else{return view!}
        button.titleLabel?.text = nil
        button.setTitle(nil, for: .normal)
        
        guard !isLoadingHashtag else{return view!}
        
        if hashtagExists{
            guard let num = numPosts else{return view!}

            var grammar = ""
            
            if num > 1{
                grammar = "s"
            }
            
            view?.numPostsLbl?.text = "\(num.kmFormatted) Post\(grammar)"
            
            view?.numPostsLbl?.setRadiusWithShadow()

            
            for sub in view?.backgroundMaskView?.subviews ?? []{
                if sub.isKind(of: UIVisualEffectView.self){
                    sub.removeFromSuperview()
                }
            }
            view?.backgroundMaskView?.addBackgroundBlur(blurEffect: UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial))
            
            switch self.hashtag?.topPost{
            case let product:
                var prefix = ""
                if product?.displaySide == "back" || product?.displaySide == "Back"{
                    prefix = "BACK_"
                }
                
                let picString = "\(prefix)\(product?.productID ?? "")"
                
                if let image = cache.imageFromCache(forKey: "\(picString)"), let color = all.tees.first(where: {$0.productCode == product?.productType})?.colors.first(where: {$0.code == product?.templateColor})?.getColor(){
                    if let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath) as? HashtagHeaderView{
                        view.backgroundImageView.image = image
                        view.backgroundImageView?.backgroundColor = color
                        let text = "\(product?.name ?? "null") - by \(product?.userInfo.fullName ?? "")"
                        view.featuredLbl?.text = text
                        if product?.userInfo.verified ?? false{
                            view.featuredLbl?.setVerified(name: text)
                        }
                        view.viewFullProductView.isHidden = false
                        self.setButtonBuy(product: product, button: button)
                    }
                    else{
                        view?.backgroundImageView.image = image
                        view?.backgroundImageView.backgroundColor = color
                        let text = "\(product?.name ?? "null") - by \(product?.userInfo.fullName ?? "")"
                        view?.featuredLbl?.text = text
                        if product?.userInfo.verified ?? false{
                            view?.featuredLbl?.setVerified(name: text)
                        }
                        view?.viewFullProductView.isHidden = false
                        self.setButtonBuy(product: product, button: button)
                    }
                }
                else{
                    fallthrough
                }
            default:
                self.getTopPostInfo(completed: { product in
                    self.hashtag?.topPost = product
                    UIApplication.shared.downloadExploreProductImage(circularProgress: nil, followingUID: product?.userInfo.uid ?? "", picID: product?.picID ?? "", index: indexPath.item, product: product, isThumbnail: false){ image in
                        guard let color = all.tees.first(where: {$0.productCode == product?.productType})?.colors.first(where: {$0.code == product?.templateColor})?.getColor()
                            else {return}
                        if let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath) as? HashtagHeaderView{
                            view.backgroundImageView.image = image
                            view.backgroundImageView.backgroundColor = color
                            let text = "\(product?.name ?? "null") - by \(product?.userInfo.fullName ?? "")"
                            view.featuredLbl?.text = text
                            if product?.userInfo.verified ?? false{
                                view.featuredLbl?.setVerified(name: text)
                            }
                            view.viewFullProductView.isHidden = false
                            self.setButtonBuy(product: product, button: button)
                        }
                        else{
                            view?.backgroundImageView.image = image
                            view?.backgroundImageView.backgroundColor = color
                            let text = "\(product?.name ?? "null") - by \(product?.userInfo.fullName ?? "")"
                            view?.featuredLbl?.text = text
                            if product?.userInfo.verified ?? false{
                                view?.featuredLbl?.setVerified(name: text)
                            }
                            view?.viewFullProductView.isHidden = false
                            self.setButtonBuy(product: product, button: button)
                        }
                    }
                })
            }
        }
        else{
            view?.numPostsLbl?.removeShadow()
            view?.numPostsLbl?.text = "This hashtag does not exist"
            view?.numPostsLbl?.setRadiusWithShadow()
        }
        
        return view!
    }
    
    func setButtonBuy(product: Product?, button: UIButton){
        if let productName = all.tees.first(where: {$0.productCode == product?.productType})?.templateDisplayName.lowercased().capitalized{
            button.setTitle(nil, for: .normal)
            button.titleLabel?.text = nil
            
            
            button.setTitle("Buy \((productName))", for: .normal)
            button.titleLabel?.text = "Buy \(productName)"
        }
    }
    
    
    func getTopPostInfo(completed: @escaping (Product?) -> ()){
        guard let userUID = pUserInfo.uid else{return}
        guard let tag = templateColor else{return}
        
        Firestore.firestore().collectionGroup("Products").whereField("Tags", arrayContains: tag).whereField("Has_Picture", isEqualTo: true).whereField("Blurred", isEqualTo: false).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Timestamp", descending: true).limit(to: 1).getDocuments(completion: { snaps, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                guard let snap = snaps?.documents.first else{
                    completed(nil)
                    return}
                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                guard let uid = snap["UID"] as? String else{
                    return}
                let isAvailable = snap["Available"] as? Bool
                let description = snap["Description"] as? String
                let name = snap["Name"] as? String
                let blurred = snap["Blurred"] as? Bool
                let templateColor = snap["Template_Color"] as? String
                let likes = snap["Likes"] as? Int
                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                let comments = ((snap["Comments"]) as? Int) ?? 0
                let isPublic = snap["Public"] as? Bool ?? true
                let productType = snap["Type"] as? String ?? defaultProductType
                let displaySide = snap["Side"] as? String ?? "front"
                let sides = snap["Sides"] as? [String] ?? ["Front"]

                

                let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: 0, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: pUserInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: isAvailable, isPublic: isPublic, productType: productType, displaySide: displaySide, supportedSides: sides)
                
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
                    
                    self.downloadUserInfo(uid: uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: true, userInfoToUse: nil, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, _, userFollowing, usersBlocking, postNotifs, postCount, followersCount, followingCount, verified in
                        
                        product.userInfo.username = username
                        product.userInfo.fullName = fullName
                        product.userInfo.dpID = dpUID
                        product.userInfo.bio = bio
                        product.userInfo.postCount = postCount
                        product.userInfo.followerCount = followersCount
                        product.userInfo.followingCount = followingCount
                        product.userInfo.userFollowing = userFollowing
                        product.userInfo.notifID = notifID
                        product.userInfo.usersBlocking = usersBlocking
                        product.userInfo.verified = verified ?? false
                        
                        if usersBlocking.contains(pUserInfo.uid ?? ""){
                            return
                        }
                        completed(product)
                        return
                    })
                })
            }
        })
    }
    
    
    var last: DocumentSnapshot!

    func getProducts(fromInterval: Int?, completed: @escaping ()->()){
        
        guard let tag = templateColor else{return}
        if fromInterval == nil{
            query = Firestore.firestore().collectionGroup("Products").whereField("Tags", arrayContains: tag).whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Likes", descending: true).limit(to: 12)
        }
        else if last != nil{
            query = Firestore.firestore().collectionGroup("Products").whereField("Tags", arrayContains: tag).whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Likes", descending: true).start(afterDocument: last).limit(to: 12)
        }
        
        guard let userUID = pUserInfo.uid else{return}
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
                                
                                if pUserInfo.usersBlocking.contains(uid){
                                    continue
                                }
                                
                                let description = snap["Description"] as? String
                                let name = snap["Name"] as? String
                                let blurred = snap["Blurred"] as? Bool
                                let templateColor = snap["Template_Color"] as? String
                                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                                let likes = snap["Likes"] as? Int
                                let comments = ((snap["Comments"]) as? Int) ?? 0
                                let productType = snap["Type"] as? String ?? defaultProductType
                                let displaySide = snap["Side"] as? String ?? "front"
                                let sides = snap["Sides"] as? [String] ?? ["Front"]

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
                                    
                                    self.loadedProducts.append(product)
                                    counter += 1
                                    if counter == docs.count{
                                        self.last = docs.last
                                        self.loadedProducts.sort(by: {$0.likes > $1.likes})
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
        
        guard self.loadedProducts.indices.contains(indexPath.item) else {
            return cell!}
        let product = self.loadedProducts[indexPath.item]
        cell?.product = product

        
        cell?.contentView.backgroundColor = UIColor(named: "ProductColor")

        let type = all.tees.first(where: {$0.productCode == product.productType})
        cell?.addConstraints(template: type)
        
        DispatchQueue(label: "cache").async {
            var prefix = ""
            if product.displaySide == "back" || product.displaySide == "Back"{
                prefix = "BACK_"
            }
            let thumbnail = "thumbnail_"
            let picString = "\(thumbnail)\(prefix)\(product.picID ?? "")"
            if let image = cache.imageFromCache(forKey: picString){
                guard let color = all.tees.first(where: {$0.productCode == product.productType})?.colors?.first(where: {$0.code == product.templateColor})
                else{return}
                var data: Data!
                
                if product.displaySide == "back" || product.displaySide == "Back"{
                    data = color.imgBack
                }
                else{
                    data = color.img
                }
                let img = UIImage(data: data)
                DispatchQueue.main.async {
                    if let index = self.loadedProducts.firstIndex(where: {$0.productID == product.productID}), let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ExploreProductCell{
                        for view in cell.canvasDisplayViews{
                            view.imageView?.image = image
                            view.setImage(image, for: .normal)
                        }
                        cell.imageView.image = img
                        cell.circularProgress.isHidden = true
                    }
                    else{
                        for view in cell?.canvasDisplayViews ?? []{
                            view.imageView?.image = image
                            view.setImage(image, for: .normal)
                        }
                        cell?.imageView.image = img
                        cell?.circularProgress.isHidden = true
                    }
                }
            } //9 14 7 3 4 4 1 20 2 2 1 5 3 4 5 1 1 6 16 3 3 7 31 13 7 44 2 2 2 2 8 2
            else{
                DispatchQueue.main.async {
                    if !(self.tokens.contains(product.picID ?? "null")){
                            cell?.circularProgress.isHidden = false
                        self.tokens.append(product.picID ?? "null")
                        UIApplication.shared.downloadExploreProductImage(circularProgress: cell?.circularProgress, followingUID: product.userInfo.uid ?? "", picID: product.picID ?? "", index: indexPath.item, product: product, isThumbnail: true){ image in
                                
                            self.tokens.removeAll(where: {$0 == product.picID})
                                
                            if let index = self.loadedProducts.firstIndex(where: {$0.productID == product.productID}){
                                collectionView.performBatchUpdates({
                                    collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
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
    '
    }
    */

}

extension UIViewController{
    
    
}

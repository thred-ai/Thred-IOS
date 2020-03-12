//
//  UserVC.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI
import AudioToolbox
import AVFoundation
import SDWebImage

let userInfo = UserInfo()
var uploadingPosts = [String]()

class UserVC: UITableViewController {
    
    var loadedProducts = [Product]()
    var isLoading = Bool()
    let uid = UserDefaults.standard.string(forKey: "UID")
    var downloader: SDWebImageDownloader? = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)

    var tokens = [String]()
        

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = self.loadedProducts[indexPath.row]

        let cell = tableView.setPictureCell(indexPath: indexPath, product: user, productLocation: self)
        return cell
        
    }
    

    var downloadingProfiles = [String]()
    var header: ProfileHeaderView?
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
        
        if !isLoading{
            
            isLoading = true
            if sender.isRefreshing{
                sender.animateRefresh()
            }
            if downloader == nil{
                downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloader?.cancelAllDownloads()
                self.tableView.downloadUserInfo(uid: userInfo.uid, userVC: self, feedVC: nil, downloadingPersonalDP: true, downloader: self.downloader, userInfo: userInfo, completed: { fullName, username, dpID, notifID, bio, image, userFollowing in
                    
                    if image != nil{
                    }
                    if username != nil{
                        
                        self.header?.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: "Edit Profile")
                        self.setUserInfo(username: username, fullname: fullName, image: image, bio: bio, notifID: notifID, dpUID: dpID, userFollowing: userFollowing)
                        
                        for product in self.loadedProducts{
                            if product.uid == userInfo.uid{
                                product.username = userInfo.username
                                product.fullName = userInfo.fullName
                                product.userImageID = dpID
                            }
                        }
                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: .none)
                        }, completion: nil)
                    }
                })
                self.downloadProducts(){                    self.isLoading = false
                    if sender.isRefreshing{
                        sender.endRefreshing()
                    }
                }
            }
        }
    }
    
    func downloadProducts(completed: @escaping () -> ()){
        self.getProducts(fromInterval: nil, refresh: true) {[weak self] hasDiffproducts, snapDocs in
            
            completed()
            if hasDiffproducts ?? false{
                self?.loadedProducts.removeAll()
                self?.cellHeights.removeAll()
                self?.tableView.reloadData()
            }
            else{
                for i in 0..<(self?.loadedProducts.count ?? 0){
                    self?.loadedProducts[i].fromCache = false
                }
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    
    deinit {
        print("going")
        //SDImageCache.shared.clear(with: .all, completion: nil)
    }
    
    
    override func viewDidLayoutSubviews() {
        
        
    }
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false

        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        header = tableView.loadUserHeaderFromNib()
        header?.actionBtn.addTarget(self, action: #selector(editProfile(_:)), for: .touchUpInside)
        if let image = userInfo.dp{
            header?.setUpInfo(username: userInfo.username, fullname: userInfo.fullName, bio: userInfo.bio, notifID: userInfo.notifID, dpUID: nil, image: image, actionBtnTitle: "Edit Profile")
        }
        tableView.addSubview(refresher)

        loadedProducts.checkAndLoadProducts(vc: self, type: "Products") { _ in
            DispatchQueue.main.async {
                self.loadedProducts.saveAllObjects(type: "Products")
                if self.loadedProducts.isEmpty{
                    self.refresh(refresher)
                }
                else{
                    for postID in uploadingPosts{
                        guard let post = self.loadedProducts.first(where: {$0.productID == postID}) else{continue}
                        self.uploadPost(post: ProductInProgress(templateColor: post.templateColor, design: cache.imageFromCache(forKey: postID), uid: post.uid, caption: post.description, name: post.name, price: (post.price ?? 20) * 100), isRetryingWithID: postID)
                    }
                }
            }
        }
        if self.navigationController?.viewControllers.first == self{
                //Clicked on profile button
            navigationController?.navigationBar.layer.shadowColor = nil
            navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
            navigationController?.navigationBar.shadowImage = UIImage.init()
            navigationItem.setRightBarButton(downBtn, animated: true)
        }
        else{
            //From Search
            
        }
        
        
    }
    
    
    @objc func editProfile(_ sender: UIButton){
        self.performSegue(withIdentifier: "editProfile", sender: nil)
    }
    
    
    @IBAction func unwindToUser(segue:  UIStoryboardSegue) {
        if let image = userInfo.dp{
            
            self.header?.setUpInfo(username: userInfo.username, fullname: userInfo.fullName, bio: userInfo.bio, notifID: userInfo.notifID, dpUID: nil, image: image, actionBtnTitle: "Edit Profile")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        else{
            
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        if self.navigationController?.viewControllers.first == self{
                //Clicked on profile button
            
            UIView.animate(withDuration: 0.2, animations: {
                (self.downBtn?.customView?.subviews.first as? UIButton)?.transform = CGAffineTransform(scaleX: 1, y: -1)
            })
        }
    }
    
    lazy var downBtn: UIBarButtonItem? = {
        
        guard let navigationBar = self.navigationController?.navigationBar else { return nil }

        let heightToSet = navigationBar.frame.height - 5

        let view = UIView(frame: CGRect(x: 0, y: 0, width: heightToSet + 10, height: heightToSet))
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: heightToSet + 10, height: heightToSet))

        view.addSubview(button)
        button.center = view.center
        
        button.addTarget(self, action: #selector(backToFeed(_:)), for: .touchUpInside)
        //button.setImage(UIImage.init(systemName: "chevron.up"), for: .normal)
        //let configuration = UIImage.SymbolConfiguration.init(pointSize: 17, weight: UIImage.SymbolWeight.black, scale: UIImage.SymbolScale.large)
        //button.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
        
        return UIBarButtonItem(customView: view)
        
    }()
    
    @objc func backToFeed(_ sender: UIButton){
        
        cache.clearMemory()
        self.performSegue(withIdentifier: "ToFeed", sender: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        downloader?.invalidateSessionAndCancel(true)
        downloader = nil
        
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        
        showCenterBtn()
        if downloader == nil{
            downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
        if !loadedProducts.isEmpty{
            self.tableView.syncPostLikes(loadedProducts: loadedProducts, vc: self)
            self.loadedProducts.saveAllObjects(type: "Products")
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if let last = self.loadedProducts.last{
                if let interval = last.timestamp{
                    if !self.isLoading{
                        self.isLoading = true
                        self.getProducts(fromInterval: interval, refresh: false){_,_ in
                             self.isLoading = false
                            if self.refreshControl?.isRefreshing ?? true{
                                self.refreshControl?.endRefreshing()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    func uploadPost(post: ProductInProgress, isRetryingWithID: String?){
        let date = Date()
        
        guard let designData = post.design.pngData() else{
        return}
        
        var doc: DocumentReference!
        
        if let docID = isRetryingWithID{
            doc = Firestore.firestore().collection("Users").document(userInfo.uid).collection("Products").document(docID)
        }
        else{
            doc = Firestore.firestore().collection("Users").document(userInfo.uid).collection("Products").document()
            uploadingPosts.append(doc.documentID)
            UserDefaults.standard.set(uploadingPosts, forKey: "UploadingPosts")

            let product = Product(uid: userInfo.uid, picID: doc.documentID, description: post.caption, fullName: userInfo.fullName, username: userInfo.username, productID: doc.documentID, userImageID: userInfo.dpID, timestamp: date, index: nil, timestampDiff: "1 second", fromCache: false, blurred: false, price: (post.price ?? 2000) / 100, name: post.name, templateColor: post.templateColor, likes: 0, liked: false, designImage: nil)
            
            cache.storeImageData(toDisk: designData, forKey: doc.documentID)
            self.loadedProducts.insert(product, at: 0)
            DispatchQueue.main.async{
                self.tableView.reloadData()
                self.loadedProducts.saveAllObjects(type: "Products")
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .middle, animated: false)
            }
        }
        
        let designRef = Storage.storage().reference().child("Users/" + userInfo.uid + "/" + "Products/" + doc.documentID + "/" + doc.documentID + ".png")
        
        designRef.putData(designData, metadata: nil, completion: { metaData, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                let data = [
                    "Name": post.name!,
                    "Description" : post.caption ?? "",
                    "Price_Cents" : post.price ?? "2000",
                    "UID" : userInfo.uid,
                    "Blurred" : false,
                    "Timestamp" : date,
                    "Template_Color" : post.templateColor ?? "null",
                    "Likes" : 0
                ] as [String : Any]
                
                doc.setData(data, completion: { error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        uploadingPosts.removeAll(where: {$0 == doc.documentID})
                        UserDefaults.standard.set(uploadingPosts, forKey: "UploadingPosts")
                        if let index = self.loadedProducts.firstIndex(where: {$0.productID == doc.documentID}){
                            self.tableView.performBatchUpdates({
                                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }, completion: nil)
                        }
                    }
                })
            }
        })
    }
    
    func getProducts(fromInterval: Date?, refresh: Bool, completed: @escaping (Bool?, [DocumentSnapshot]?) -> ()){
        
        
        /*
         QUERY COMMENTS:
         - ORDERING THE "Timestamp" VALUE BY THE EARLIEST TIME
         - STARTING FROM THE LOCAL \(fromInterval) VAR
         - RETRIEVING DOCUMENT SNAPSHOTS IN THE \(snapDocuments) VAR
         - IF THERE IS AN ERROR, IT WILL BE IN THE \(err) VAR
         - A COMMENT WILL EITHER BE A PICTURE OR TEXT, NOT BOTH
         */
            
        var query: Query! = nil
        //REMOVE LATER
        //
        
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(userInfo.uid).collection("Products").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        else if let last = fromInterval{
            query = Firestore.firestore().collection("Users").document(userInfo.uid).collection("Products").whereField("Timestamp", isLessThan: Timestamp(date: last)).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        query.getDocuments(completion: { (snapDocuments, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completed(false, nil)
                return
            }
            else{
                if snapDocuments?.isEmpty ?? true{
                    if refresh{
                        completed(true, nil)
                        self.loadedProducts.removeOldFeedPosts(newPosts: nil){
                            self.loadedProducts.removeAllObjects(type: "Products")
                        }
                    }
                    else{
                        completed(false, nil)
                    }
                }
                else{
                    guard let snaps = snapDocuments?.documents else {
                        
                        return}
                    if snapDocuments?.metadata.isFromCache ?? false{
                        completed(false, snaps)
                    }
                    else{
                        
                        var localLoaded: [Product]! = [Product]()
                        switch fromInterval{
                        case .none:
                            for (index, snap) in snaps.enumerated(){
                                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                                let uid = snap["UID"] as! String
                                let description = snap["Description"] as? String
                                let name = snap["Name"] as? String
                                let blurred = snap["Blurred"] as? Bool
                                let templateColor = snap["Template_Color"] as? String

                                let likes = snap["Likes"] as? Int ?? 0

                                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                                
                                localLoaded.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, fromCache: false, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: nil, designImage: nil))

                                if localLoaded.count == snaps.count{
                                    let isSame = localLoaded == self.loadedProducts
                                    
                                    print(localLoaded.count)
                                    print(self.loadedProducts.count)
                                    
                                    if !isSame{
                                        self.loadedProducts.removeOldFeedPosts(newPosts: localLoaded){
                                            localLoaded = nil
                                            completed(true, snaps)
                                            self.sortDownloadedProducts(snaps: snaps){
                                                self.loadedProducts.saveAllObjects(type: "Products")
                                            }
                                        }
                                    }
                                    else{
                                        localLoaded = nil
                                        completed(false, snaps)
                                    }
                                }
                            }
                        default:
                            self.sortDownloadedProducts(snaps: snaps){
                                completed(true, snaps)
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    func sortDownloadedProducts(snaps: [QueryDocumentSnapshot], completed: @escaping () -> ()){
        
        var productsToUse: [Product]! = [Product]()
        for (index, snap) in snaps.enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
        
            if !loadedProducts.contains(where: {$0.productID == snap.documentID}){
                
                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                let uid = snap["UID"] as! String
                let description = snap["Description"] as? String
                let name = snap["Name"] as? String
                let blurred = snap["Blurred"] as? Bool
                let templateColor = snap["Template_Color"] as? String
                let likes = snap["Likes"] as? Int
                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                
                
                
                Firestore.firestore().collection("Users").document(uid).collection("Products").document(snap.documentID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userInfo.uid).getDocuments(completion: { snapLikes, error in
                
                    var liked: Bool!
                    
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        userInfo.userLiked?.removeAll(where: {$0 == snap.documentID})
                        if let likeDocs = snapLikes?.documents{
                            if likeDocs.isEmpty{
                                liked = false
                            }
                            else{
                                liked = true
                                if !(userInfo.userLiked?.contains(snap.documentID) ?? true){
                                    userInfo.userLiked?.append(snap.documentID)
                                }
                            }
                        }
                        else{
                            liked = false
                        }
                    }
                    
                    productsToUse.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, fromCache: false, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: nil))
                    
                    print("ProductsToUse: \(productsToUse.count)")
                    print("Snaps: \(snaps.count)")

                    
                    if productsToUse.count == snaps.count{
                        UserDefaults.standard.set(userInfo.userLiked, forKey: "LikedPosts")
                        let sorted = productsToUse.sorted(by: {$0.timestamp > $1.timestamp})
                        for product in sorted{
                            self.loadedProducts.append(product)
                            self.tableView.performBatchUpdates({
                                self.tableView.insertRows(at: [IndexPath(row: self.loadedProducts.count - 1, section: 0)], with: .none)
                            }, completion: { finished in
                                if finished{
                                    if product == sorted.last{
                                        completed()
                                        productsToUse.removeAll()
                                        productsToUse = nil
                                    }
                                }
                            })
                        }
                    }
                })
            }
        }
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.loadedProducts.count
    }
    
    
    var cellHeights: [IndexPath: CGFloat] = [:]
    
    ///* Dynamic Cell Sizing *///
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ///For every cell, retrieve the height value and store it in the dictionary
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 1500
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let product = loadedProducts[indexPath.row]
        guard let cell = tableView.cellForRow(at: indexPath) as? ProductCell else{return}
        guard let imageData = product.designImage ?? cell.productPicture.makeSnapshot(clear: false, subviewsToIgnore: [])?.pngData() else{
            return
        }
        DispatchQueue.main.async {
            product.designImage = imageData
            self.productToOpen = product
            self.performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        likeQueue.removeAll()
        DispatchQueue.global(qos: .background).sync {
            cache.clearMemory()
        }
    }
    
    var productToOpen = Product()
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
    }
}



extension UIViewController{
    
    func setUserInfo(username: String?, fullname: String?, image: UIImage?, bio: String?, notifID: String?, dpUID: String?, userFollowing: [String]?){
        if let usernameToSet = username{
            UserDefaults.standard.set(usernameToSet, forKey: "USERNAME")
            userInfo.username = usernameToSet
        }
        if let fullnameToSet = fullname{
            UserDefaults.standard.set(fullnameToSet, forKey: "FULLNAME")
            userInfo.fullName = fullnameToSet
        }
        if let bioToSet = bio{
            UserDefaults.standard.set(bioToSet, forKey: "BIO")
            userInfo.bio = bioToSet
        }
        if let notifIDToSet = notifID{
            UserDefaults.standard.set(notifIDToSet, forKey: "NOTIF_ID")
            userInfo.notifID = notifIDToSet
        }
        if let userFollowing = userFollowing{
            UserDefaults.standard.set(userFollowing, forKey: "FOLLOWING")
            userInfo.userFollowing = userFollowing
        }
        if let dpIDToSet = dpUID{
            UserDefaults.standard.set(dpIDToSet, forKey: "DP_ID")
            userInfo.dpID = dpIDToSet
            guard let img = image else{
                return}
            userInfo.dp = img
            SDImageCache.shared.storeImageData(toDisk: img.jpegData(compressionQuality: 1.0), forKey: dpIDToSet)
        }
    }
}




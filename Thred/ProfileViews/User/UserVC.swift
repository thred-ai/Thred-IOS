//
//  UserVC.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseUI
import AudioToolbox
import AVFoundation
import SDWebImage
import ColorCompatibility
import BRYXBanner

var userInfo = UserInfo()
var uploadingPosts = [String]()

class UserVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var loadedProducts = [Product]()
    @IBOutlet var tableView: UITableView!
    var isLoading = true
    let uid = UserDefaults.standard.string(forKey: "UID")
    var selectedUser: UserInfo!
    var tokens = [String]()
    var offsets = [CGFloat]()
       
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = self.loadedProducts[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "PictureProduct", for: indexPath) as? ProductCell
        tableView.setPictureCell(cell: cell, indexPath: indexPath, product: user, productLocation: self, shouldDownloadPic: true)
        return cell!
        
    }
    

    var downloadingProfiles = [String]()
    var header: ProfileHeaderView?
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
        
        guard checkInternetConnection() else{
            sender.endRefreshing()
            return
        }
        if !isLoading{
            isLoading = true
            if sender.isRefreshing{
                sender.animateRefresh()
            }
            guard let uid = userInfo.uid else{return}
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadUserInfo(uid: uid, userVC: self, feedVC: nil, downloadingPersonalDP: true, doNotDownloadDP: false, userInfoToUse: userInfo, queryOnUsername: false, completed: {uid, fullName, username, dpID, notifID, bio, image, userFollowing, usersBlocking, postCount, followerCount, followingCount, profileLink  in
                    
                    if username != nil{
                        
                        self.header?.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: "Edit Profile", followerCount: followerCount, followingCount: followingCount, postCount: postCount)
                        self.setUserInfo(username: username, fullname: fullName, image: image, bio: bio, notifID: notifID, dpUID: dpID, userFollowing: userFollowing, followerCount: followerCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking, profileLink: profileLink)
                        
                        for product in self.loadedProducts{
                            if product.userInfo.uid == userInfo.uid{
                                product.userInfo.username = userInfo.username
                                product.userInfo.fullName = userInfo.fullName
                                product.userInfo.dpID = dpID
                            }
                        }
                        self.tableView?.performBatchUpdates({
                            self.tableView?.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: .none)
                        }, completion: nil)
                    }
                })
                self.downloadProducts(){
                    self.isLoading = false
                    if sender.isRefreshing{
                        sender.endRefreshing()
                    }
                }
            }
        }
    }
    
    func downloadProducts(completed: @escaping () -> ()){
        getProducts(fromInterval: nil, refresh: true) { hasDiffproducts in
            if hasDiffproducts ?? false{
                if !self.loadedProducts.isEmpty{
                    completed()
                    self.loadedProducts.removeAll()
                    self.cellHeights.removeAll()
                    self.tableView?.reloadData()
                    self.offsets.removeAll()
                    for cell in (self.tableView.visibleCells as! [ProductCell]){
                        cell.collectionViewOffset = 0
                    }
                }
                else{
                    DispatchQueue.main.async {
                        completed()
                        self.tableView?.reloadData()
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    completed()
                    self.tableView?.reloadData()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        
    }
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false

        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        tableView.allowsSelection = false
        header = tableView.loadUserHeaderFromNib()
        header?.actionBtn.addTarget(self, action: #selector(editProfile(_:)), for: .touchUpInside)
        header?.optionBtn.setImage(UIImage(named: "gear"), for: .normal)
        header?.optionBtn.addTarget(self, action: #selector(toSettings(_:)), for: .touchUpInside)
        if let image = userInfo.dp{
            header?.setUpInfo(username: userInfo.username, fullname: userInfo.fullName, bio: userInfo.bio, notifID: userInfo.notifID, dpUID: userInfo.dpID, image: image, actionBtnTitle: "Edit Profile", followerCount: userInfo.followerCount, followingCount: userInfo.followingCount, postCount: userInfo.postCount)
        }
        tableView.addSubview(refresher)

        loadedProducts.checkAndLoadProducts(vc: self, type: "Products") { _ in
            DispatchQueue.main.async {
                self.loadedProducts.saveAllObjects(type: "Products")
                self.isLoading = false
                self.refresh(refresher)
                if self.loadedProducts.isEmpty{
                }
                else{
                    
                    for postID in uploadingPosts{
                        
                        guard let post = self.loadedProducts.first(where: {$0.productID == postID}) else{
                            continue}
                        
                        guard let color = post.templateColor else{return}
                        
                        
                        guard let design = cache.imageFromCache(forKey: postID) else{return}
                        
                        guard let designImage = post.designImage else{
                            uploadingPosts.removeAll(where: {$0 == postID})
                            UserDefaults.standard.set(uploadingPosts, forKey: "UploadingPosts")
                            self.loadedProducts.removeAll(where: {$0.productID == post.productID})
                            self.loadedProducts.saveAllObjects(type: "Products")
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            return}
                        
                        self.uploadPost(post: ProductInProgress(templateColor: color, design: design, uid: post.userInfo.uid, caption: post.description, name: post.name, price: (post.price ?? 20) * 100, productID: postID, display: designImage), isRetryingWithID: postID)
                    }
                }
            }
        }
    }
    
    @objc func toSettings(_ sender: UIButton){
        performSegue(withIdentifier: "toSettings", sender: nil)
    }
    
    
    @objc func editProfile(_ sender: UIButton){
        self.performSegue(withIdentifier: "editProfile", sender: nil)
    }
    
    
    @IBAction func unwindToUser(segue:  UIStoryboardSegue) {
        if let image = userInfo.dp{
            
            self.header?.setUpInfo(username: userInfo.username, fullname: userInfo.fullName, bio: userInfo.bio, notifID: userInfo.notifID, dpUID: userInfo.dpID, image: image, actionBtnTitle: "Edit Profile", followerCount: userInfo.followerCount, followingCount: userInfo.followingCount, postCount: userInfo.postCount)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        else{
            
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    lazy var didTapBlock: () -> () = {
        self.showAuthMessage {
            
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        
        showCenterBtn()
        if !loadedProducts.isEmpty{
            self.tableView.syncPostLikes(loadedProducts: loadedProducts, vc: self)
            self.loadedProducts.saveAllObjects(type: "Products")
        }
        checkAuthStatus {
            if let user = Auth.auth().currentUser{
                if user.phoneNumber != nil{
                    let banner = Banner(title: "Login info needs to be updated!", subtitle: "Click here to view the full announcement", image: nil, backgroundColor: .systemRed, didTapBlock: self.didTapBlock)
                    banner.titleLabel.textAlignment = .center
                    banner.titleLabel.font = UIFont(name: "NexaW01-Heavy", size: 16)
                    banner.detailLabel.textAlignment = .center
                    banner.show()
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if let last = self.loadedProducts.last{
                if let interval = last.timestamp{
                    if !self.isLoading{
                        self.isLoading = true
                        self.getProducts(fromInterval: interval, refresh: false){_ in
                             self.isLoading = false
                            if self.tableView.refreshControl?.isRefreshing ?? true{
                                self.tableView.refreshControl?.endRefreshing()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func uploadPost(post: ProductInProgress, isRetryingWithID: String?){
        let date = Date()
        
        guard let designData = post.design?.pngData() else{
            return}
        guard let linkData = post.display else{
            return}
        
        var doc: DocumentReference!
        guard let uid = userInfo.uid else{return}
        if let docID = isRetryingWithID{
            doc = Firestore.firestore().collection("Users").document(uid).collection("Products").document(docID)
        }
        else{
            doc = Firestore.firestore().collection("Users").document(uid).collection("Products").document()
            uploadingPosts.append(doc.documentID)
            UserDefaults.standard.set(uploadingPosts, forKey: "UploadingPosts")

            let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil), picID: doc.documentID, description: post.caption, productID: doc.documentID, timestamp: date, index: nil, timestampDiff: "1 second", blurred: false, price: (post.price ?? 2000) / 100, name: post.name, templateColor: post.templateColor, likes: 0, liked: false, designImage: post.display, comments: 0, link: nil, isAvailable: true)
            
            cache.storeImageData(toDisk: designData, forKey: doc.documentID)
            self.loadedProducts.insert(product, at: 0)
            DispatchQueue.main.async{
                self.tableView?.reloadData()
                self.loadedProducts.saveAllObjects(type: "Products")
                self.tableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .middle, animated: false)
            }
        }
        
        let data = [
            "Name" : post.name!,
            "Search_Name" : post.name?.lowercased() ?? "post",
            "Description" : post.caption ?? "",
            "Price_Cents" : post.price ?? "2000",
            "UID" : uid,
            "Blurred" : false,
            "Timestamp" : date,
            "Template_Color" : post.templateColor ?? "null",
            "Likes" : 0,
            "Comments" : 0,
            "Has_Picture" : false,
            "Product_ID" : doc.documentID,
            "Available" : true
        ] as [String : Any]
        
        
        
        doc.setData(data, completion: { error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                let designRef = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + doc.documentID + "/" + doc.documentID + ".png")
                designRef.putData(designData, metadata: nil, completion: { metaData, error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        let linkRef = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + doc.documentID + "/" + "link_" + doc.documentID + ".png")
                        linkRef.putData(linkData, metadata: nil, completion: { metaData, error in
                            if error != nil{
                                print(error?.localizedDescription ?? "")
                            }
                            else{
                                uploadingPosts.removeAll(where: {$0 == doc.documentID})
                                UserDefaults.standard.set(uploadingPosts, forKey: "UploadingPosts")
                                self.tableView.performBatchUpdates({
                                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                                }, completion: nil)
                            }
                        })
                    }
                })
            }
        })
    }
    
    func getProducts(fromInterval: Date?, refresh: Bool, completed: @escaping (Bool?) -> ()){
        
        
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
        guard let uid = userInfo.uid else{return}

        var localLoaded: [Product]! = [Product]()

        
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(uid).collection("Products").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).whereField("Available", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        else if let last = fromInterval{
            query = Firestore.firestore().collection("Users").document(uid).collection("Products").whereField("Timestamp", isLessThan: Timestamp(date: last)).whereField("Available", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        query.getDocuments(completion: { (snapDocuments, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completed(false)
                return
            }
            else{
                if snapDocuments?.isEmpty ?? true{
                    if refresh{
                        completed(true)
                        self.loadedProducts.removeOldFeedPosts(newPosts: nil)
                        self.loadedProducts.removeAllObjects(type: "Products")
                    }
                    else{
                        completed(false)
                    }
                }
                else{
                    
                    guard let snaps = snapDocuments?.documents else {
                        
                        return}
                    if snapDocuments?.metadata.isFromCache ?? false{
                        completed(false)
                    }
                    else{
                        

                        for (index, snap) in snaps.enumerated(){
                            let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                            let uid = snap["UID"] as! String
                            let description = snap["Description"] as? String
                            let name = snap["Name"] as? String
                            let blurred = snap["Blurred"] as? Bool
                            let templateColor = snap["Template_Color"] as? String

                            let likes = snap["Likes"] as? Int ?? 0

                            guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                            let comments = ((snap["Comments"]) as? Int) ?? 0

                            localLoaded.append(Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil), picID: snap.documentID, description: description,  productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: true))
                        }
                    }
                    if fromInterval == nil{
                        self.checkSameProducts(localLoaded: localLoaded, completed: { isNew in
                            if isNew{
                                completed(true)
                            }
                            else{
                                completed(false)
                            }
                        })
                    }
                    else{
                        self.sortDownloadedProducts(products: localLoaded){
                            completed(true)
                        }
                    }
                }
            }
        })
    }
    
    func checkSameProducts(localLoaded: [Product], completed: @escaping (Bool) -> ()){
        let isSame = localLoaded == self.loadedProducts
        if !isSame{
            self.loadedProducts.removeOldFeedPosts(newPosts: localLoaded)
            completed(true)
            self.sortDownloadedProducts(products: localLoaded){
                //localLoaded = nil
                self.loadedProducts.saveAllObjects(type: "Products")
            }
        }
        else{
            //localLoaded = nil
            completed(false)
        }
    }
    
    func sortDownloadedProducts(products: [Product], completed: @escaping () -> ()){
        
        var productsToUse: [Product]! = [Product]()
        for product in products{ // LOADED DOCUMENTS FROM \(snapDocuments)
            guard let uid = product.userInfo.uid else{continue}
            if !loadedProducts.contains(where: {$0.productID == product.productID}){
                
                guard let userUID = userInfo.uid else{return}
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
                    
                    productsToUse.append(product)
           
                    if productsToUse.count == products.count{
                        
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadedProducts.count
    }

    
    lazy var headerView: UIView? = {
        
        return loadProfilePostHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if loadedProducts.isEmpty{
            if isLoading{
                loadingView?.spinner.animate()
                return loadingView
            }
            else{
                return headerView
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if loadedProducts.isEmpty{
            return 150
        }
        return 0
    }
    
    var cellHeights: [IndexPath: CGFloat] = [:]
    
    ///* Dynamic Cell Sizing *///
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ///For every cell, retrieve the height value and store it in the dictionary
        if let cell = cell as? ProductCell{
            if offsets.indices.contains(indexPath.row){
                cell.collectionViewOffset = offsets[indexPath.row]
            }
            else{
                cell.collectionViewOffset = 0
            }
        }
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ProductCell{
            if offsets.indices.contains(indexPath.row){
                offsets[indexPath.row] = cell.collectionViewOffset
            }
            else{
                offsets.append(cell.collectionViewOffset)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 1500
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let product = loadedProducts[indexPath.row]

        if uploadingPosts.contains(product.productID){
            return nil
        }
        return indexPath
    }
    
    var productToOpen = Product()
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
        else if let commentsVC = segue.destination as? CommentsVC{
            commentsVC.post = productToOpen
        }
        else if let listVC = segue.destination as? UserListVC{
            listVC.listType = header?.selectedList
            listVC.user = userInfo
        }
        else if let friendVC = segue.destination as? FriendVC{
            friendVC.friendInfo = selectedUser
        }
        else if let designVC = (segue.destination as? UINavigationController)?.viewControllers.first as? DesignViewController{
            if let img = cache.imageFromCache(forKey: productToOpen.productID){
                designVC.product = ProductInProgress(templateColor: productToOpen.templateColor, design: img, uid: productToOpen.userInfo.uid, caption: productToOpen.description, name: productToOpen.name, price: productToOpen.price, productID: productToOpen.productID, display: productToOpen.designImage)
            }
        }
    }
}



extension UIViewController{
    
    func setUserInfo(username: String?, fullname: String?, image: Data?, bio: String?, notifID: String?, dpUID: String?, userFollowing: [String]?, followerCount: Int?, postCount: Int?, followingCount: Int?, usersBlocking: [String]?, profileLink: URL?){
        
        UserDefaults.standard.set(username, forKey: "USERNAME")
        userInfo.username = username
        
        UserDefaults.standard.set(fullname, forKey: "FULLNAME")
        userInfo.fullName = fullname
        
        UserDefaults.standard.set(bio, forKey: "BIO")
        userInfo.bio = bio
        
        UserDefaults.standard.set(notifID, forKey: "NOTIF_ID")
        userInfo.notifID = notifID
        
        UserDefaults.standard.set(userFollowing, forKey: "FOLLOWING")
        userInfo.userFollowing = userFollowing ?? []
        
        UserDefaults.standard.set(followerCount, forKey: "FOLLOWER_COUNT")
        userInfo.followerCount = followerCount ?? 0
        
        UserDefaults.standard.set(postCount, forKey: "POST_COUNT")
        userInfo.postCount = postCount ?? 0
        
        UserDefaults.standard.set(followingCount, forKey: "FOLLOWING_COUNT")
        userInfo.followingCount = followingCount ?? 0
        
        UserDefaults.standard.set(followingCount, forKey: "BLOCKING")
        userInfo.usersBlocking = usersBlocking ?? []
        
        UserDefaults.standard.set(profileLink, forKey: "PROFILE_LINK")
        userInfo.profileLink = profileLink
        
        UserDefaults.standard.set(dpUID, forKey: "DP_ID")
        userInfo.dpID = dpUID
        guard let img = image ?? defaultDP else{
            return}
        userInfo.dp = img
        SDImageCache.shared.storeImageData(toDisk: img, forKey: dpUID)
    }
}




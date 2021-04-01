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
import FirebaseFirestore
import PopupDialog
import StoreKit
import FirebaseAnalytics

var pUserInfo = UserInfo()
var uploadingPosts = [ProductInProgress]()


class UserVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var loadedProducts = [Product]()
    var isLoading = true
    let uid = UserDefaults.standard.string(forKey: "UID")
    var selectedUser: UserInfo!
    var hashtagToOpen: Hashtag?
    var tokens = [String]()
    var offsets = [CGFloat]()

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind{
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerCell", for: indexPath) as? ProfileHeaderView
            view?.setUpInfo(username: pUserInfo.username, fullname: pUserInfo.fullName, bio: pUserInfo.bio, notifID: pUserInfo.notifID, dpUID: pUserInfo.dpID, image: pUserInfo.dp, actionBtnTitle: "Edit Profile", followerCount: pUserInfo.followerCount, followingCount: pUserInfo.followingCount, postCount: pUserInfo.postCount, verified: pUserInfo.verified)
            view?.loadedPosts.removeAll()
            view?.getStories {
                view?.collectionView.reloadData()
            }
            return view!
        default:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "EmptyProfile", for: indexPath) as? EmptyProfileProductsView
            view?.loadingView?.isHidden = true
            
            if loadedProducts.isEmpty{
                if isLoading{
                    view?.spinner?.animate()
                    view?.loadingView?.isHidden = false
                }
            }
            
            return view!
        }
    }
    
    lazy var header: ProfileHeaderView = {
        let view = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).first as? ProfileHeaderView
        return view ?? ProfileHeaderView()
    }()

    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = loadedProducts[indexPath.item]
        self.productToOpen = product
        self.performSegue(withIdentifier: "toFull", sender: nil)
    }

    var downloadingProfiles = [String]()
    
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl?){
        
        guard checkInternetConnection() else{
            sender?.endRefreshing()
            return
        }
        if !isLoading{
            isLoading = true
            if sender?.isRefreshing ?? false{
                sender?.animateRefresh()
            }
            guard let uid = pUserInfo.uid else{return}
            var timer: DispatchTime = .now()
            if sender != nil{
                timer = .now() + 1
            }
            DispatchQueue.main.asyncAfter(deadline: timer) {
                self.downloadUserInfo(uid: uid, userVC: self, feedVC: nil, downloadingPersonalDP: true, doNotDownloadDP: false, userInfoToUse: pUserInfo, queryOnUsername: false, completed: {uid, fullName, username, dpID, notifID, bio, image, userFollowing, usersBlocking, postNotifs, postCount, followerCount, followingCount, verified in
                    
                    if username != nil{
                        
                        self.header.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: "Edit Profile", followerCount: followerCount, followingCount: followingCount, postCount: postCount, verified: verified ?? false)
                        self.setUserInfo(username: username, fullname: fullName, image: image, bio: bio, notifID: notifID, dpUID: dpID, userFollowing: userFollowing, followerCount: followerCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking, verified: verified ?? false)
                        
                        for product in self.loadedProducts{
                            if product.userInfo.uid == pUserInfo.uid{
                                product.userInfo.username = pUserInfo.username
                                product.userInfo.fullName = pUserInfo.fullName
                                product.userInfo.dpID = dpID
                                product.userInfo.verified = verified ?? false
                            }
                        }
                        self.collectionView?.performBatchUpdates({
                            self.collectionView?.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                        }, completion: nil)
                    }
                })
                self.downloadProducts(){
                    self.isLoading = false
                    if sender?.isRefreshing ?? false{
                        sender?.endRefreshing()
                    }
                }
            }
        }
        else{
            sender?.endRefreshing()
        }
    }

    func clearTableView(){
        self.loadedProducts.removeAll()
        self.offsets.removeAll()
        self.collectionView.reloadData()
    }
    
    func downloadProducts(completed: @escaping () -> ()){
        
        getProducts(fromInterval: nil, refresh: true) { hasDiffproducts in
            if hasDiffproducts ?? false{
                if !self.loadedProducts.isEmpty{
                    self.clearTableView()
                    DispatchQueue.main.async {
                        completed()
                    }
                }
                else{
                    DispatchQueue.main.async {
                        completed()
                    }
                }
            }
            else{
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    completed()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if loadedProducts.isEmpty{
            return CGSize(width: collectionView.frame.width, height: 120)
        }
        else{
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        
    }
    
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false

        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        collectionView.register(UINib(nibName: "ExploreProductCell", bundle: nil), forCellWithReuseIdentifier: "ExploreProductCell")
        
        collectionView.addSubview(refresher)

        
        
        loadedProducts.checkAndLoadProducts(vc: self, type: "Products") { _ in
            DispatchQueue.main.async {
                self.loadedProducts.saveAllObjects(type: "Products")
                self.isLoading = false
                self.refresh(nil)
                if self.loadedProducts.isEmpty{
                }
                else{
                    
                    for post in uploadingPosts{
                                                               
                        guard let color = post.templateColor else{return}
                        
                        let designs = post.designs
                        
                        guard let designImage = post.display else{
                            uploadingPosts.removeAll(where: {$0.productID == post.productID})
                            uploadingPosts.saveAll(type: "UploadProducts")
                            self.loadedProducts.removeAll(where: {$0.productID == post.productID})
                            self.loadedProducts.saveAllObjects(type: "Products")
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                            return}
                        if self.currentUploadingPost?.productID == post.productID{continue}
                        
                        self.uploadPost(post: ProductInProgress(templateColor: color, designs: designs, uid: pUserInfo.uid, caption: post.caption, name: post.name, price: (post.price ?? 20) * 100, productID: post.productID, display: designImage, isPublic: post.isPublic, productType: post.productType, displaySide: post.displaySide), isRetryingWithID: post.productID)
                    }
                }
            }
        }
    }
    
    var currentUploadingPost: ProductInProgress!
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        
        cell?.contentView.backgroundColor = UIColor(named: "ProductColor")

        cell?.product = product
        
        var prefix = ""
        if product.displaySide == "back" || product.displaySide == "Back"{
            prefix = "BACK_"
        }
                
        let type = all.tees.first(where: {$0.productCode == product.productType})
        cell?.addConstraints(template: type)
        
        DispatchQueue(label: "cache").async {
            if let image = cache.imageFromCache(forKey: "thumbnail_\(prefix)\(product.picID ?? "")"){
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
                        if !(product.isAvailable ?? false){
                            cell.imageView.alpha = 0.5
                        }
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
            }
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
    
    @IBAction func unwindToUser(segue:  UIStoryboardSegue) {
        if let image = pUserInfo.dp{
            
            self.header.setUpInfo(username: pUserInfo.username, fullname: pUserInfo.fullName, bio: pUserInfo.bio, notifID: pUserInfo.notifID, dpUID: pUserInfo.dpID, image: image, actionBtnTitle: "Edit Profile", followerCount: pUserInfo.followerCount, followingCount: pUserInfo.followingCount, postCount: pUserInfo.postCount, verified: pUserInfo.verified)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
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

    override func viewWillAppear(_ animated: Bool) {
        showCenterBtn()
        if !loadedProducts.isEmpty{
            //self.tableView.syncPostLikes(loadedProducts: loadedProducts, vc: self)
            self.loadedProducts.saveAllObjects(type: "Products")
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.size.height) / 2{
            print("fromScroll")
            if let last = self.loadedProducts.last{
                if let interval = last.timestamp{
                    if !self.isLoading, canLoadMore{
                        self.isLoading = true
                        self.getProducts(fromInterval: interval, refresh: false){_ in
                            self.isLoading = false
                            if self.collectionView.refreshControl?.isRefreshing ?? true{
                                self.collectionView.refreshControl?.endRefreshing()
                            }
                        }
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
    
    var BubbleTimer:Timer?

    
    func addBankBalloonPopUp(product: Product!){
        
        setupUI()

        showBankMessage(product: product, completed: {
            product?.sharePost(progressView: nil)
        })
    }
    
    func setupUI() {
        BubbleTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.startBalloon), userInfo: nil, repeats: true)
    }
    
    func showBankMessage(product: Product!, completed: @escaping () -> ()){
        let title = "WOO HOO!"
        guard let productName = all.tees.first(where: {$0.productCode == product.productType})?.templateDisplayName.lowercased()

        else {return}
        let message = "Congrats on making your first Thred post! Share it with friends and family so they can check out your \(productName)!"
        
        let yesBtn = DefaultButton(title: "SHARE \((productName).uppercased())", dismissOnTap: true) {
            self.BubbleTimer?.invalidate()
            self.BubbleTimer = nil
            completed()
        }
         
        let cancelBtn = DefaultButton(title: "MAYBE LATER", dismissOnTap: true) {
            self.BubbleTimer?.invalidate()
            self.BubbleTimer = nil
        }
                
        UIApplication.topViewController()?.showPopUp(title: title, message: message, image: nil, buttons: [yesBtn, cancelBtn], titleColor: .label, blurBack: false)
    }
    
    
    
    func uploadPost(post: ProductInProgress, isRetryingWithID: String?){
        let date = Date()
        
        let designData = post.designs
        guard let imgData = post.display else{return}
        guard let linkData = post.display else{
            return}
        
        if let color = all.tees.first(where: {$0.productCode == post.productType})?.colors.first(where: {$0.code == post.templateColor})?.display{
            Analytics.logEvent("create_new_product", parameters: [
                "name": post.name ?? "",
                "type": post.productType ?? "",
                "visibility": post.isPublic ?? true,
                "color": color,
                "full_text": "A product was shared with a Dynamic Link"
            ])
        }
        
        var doc: DocumentReference!
        guard let uid = pUserInfo.uid else{return}
        guard let color = all.tees.first(where: {$0.productCode == post.productType})?.colors?.first(where: {$0.code == post.templateColor})?.getColor()
        else{return}
        
        guard let tab = self.tabBarController as? MainTabBarViewController else{return}
        tab.spinner.isHidden = false
        tab.button.setImage(UIImage(data: imgData), for: .normal)
        tab.button.backgroundColor = color
        tab.spinner.animate()
        
        if let docID = isRetryingWithID{
            doc = Firestore.firestore().collection("Users").document(uid).collection("Products").document(docID)
        }
        else{
            doc = Firestore.firestore().collection("Users").document(uid).collection("Products").document()
            post.productID = doc.documentID
            uploadingPosts.append(post)
            uploadingPosts.saveAll(type: "UploadProducts")
            
            for design in designData{
                var prefix = ""
                if design?.side.name == "back" || design?.side.name == "Back"{
                    prefix = "BACK_"
                }
                let picString = "\(prefix)\(post.productID ?? "")"
                cache.storeImageData(toDisk: design?.img, forKey: "thumbnail_\(picString)")
            }
        }
        
        currentUploadingPost = post

        
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
            "Available" : true,
            "Public" : post.isPublic ?? true,
            "Type" : post.productType ?? defaultProductType,
            "Side" : post.displaySide ?? "front",
            "Sides" : post.designs.compactMap({$0?.side?.name})
        ] as [String : Any]
        
        
        doc.setData(data, completion: { error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                self.uploadDesigns(uid: uid, doc: doc, designs: post.designs, completed: {
                    self.uploadDisplay(uid: uid, doc: doc, linkData: linkData, completed: {
                        uploadingPosts.removeAll(where: {$0.productID == doc.documentID})
                        uploadingPosts.saveAll(type: "UploadProducts")
                        tab.spinner.isHidden = true
                        tab.button.setImage(UIImage(systemName: "plus"), for: .normal)
                        tab.button.backgroundColor = .systemBackground
                        if !self.loadedProducts.contains(where: {$0.productID == post.productID}){
                            let product = Product(userInfo: pUserInfo, picID: doc.documentID, description: post.caption, productID: doc.documentID, timestamp: date, index: nil, timestampDiff: "1 second", blurred: false, price: (post.price ?? 2000) / 100, name: post.name, templateColor: post.templateColor, likes: 0, liked: false, designImage: post.display, comments: 0, link: nil, isAvailable: true, isPublic: post.isPublic ?? true, productType: post.productType, displaySide: post.displaySide, supportedSides: designData.compactMap({$0?.side.name}))
                            self.loadedProducts.insert(product, at: 0)
                        }
                        DispatchQueue.main.async{
                            self.collectionView?.reloadData()
                            self.loadedProducts.saveAllObjects(type: "Products")
                            self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredVertically, animated: true)
                            pUserInfo.postCount += 1
                            self.header.setUpInfo(username: pUserInfo.username, fullname: pUserInfo.fullName, bio: pUserInfo.bio, notifID: pUserInfo.notifID, dpUID: pUserInfo.dpID, image: pUserInfo.dp, actionBtnTitle: "Edit Profile", followerCount: pUserInfo.followerCount, followingCount: pUserInfo.followingCount, postCount: pUserInfo.postCount, verified: pUserInfo.verified)
                            self.setUserInfo(username: pUserInfo.username, fullname: pUserInfo.fullName, image: pUserInfo.dp, bio: pUserInfo.bio, notifID: pUserInfo.notifID, dpUID: pUserInfo.dpID, userFollowing: pUserInfo.userFollowing, followerCount: pUserInfo.followerCount, postCount: pUserInfo.postCount, followingCount: pUserInfo.followingCount, usersBlocking: pUserInfo.usersBlocking, verified: pUserInfo.verified)
                            self.checkPostPopups()
                        }
                    })
                })
                
            }
        })
    }
    
    func uploadDesigns(uid: String, doc: DocumentReference, designs: [Design?], completed: @escaping () -> ()){

        var uploadedDesignsCount = 0
        for design in designs{
            
            guard let data = design?.img else{continue}
            var prefix = ""
            if design?.side.name == "Back"{
                prefix = "BACK_"
            }
            
            let designRef = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + doc.documentID + "/" + "\(prefix)" + doc.documentID + ".png")

            designRef.putData(data, metadata: nil, completion: { metaData, error in
                uploadedDesignsCount += 1
                if error != nil{
                    print(error?.localizedDescription ?? "")
                }
                if uploadedDesignsCount == designs.count{
                    completed()
                }
            })
        }
    }
    
    func uploadDisplay(uid: String, doc: DocumentReference, linkData: Data, completed: @escaping () -> ()){
        let linkRef = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + doc.documentID + "/" + "link_" + doc.documentID + ".png")
        linkRef.putData(linkData, metadata: nil, completion: { metaData, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                completed()
            }
        })
    }
    
    func checkPostPopups(){
        switch pUserInfo.postCount{
        case 1:
            if !UserDefaults.standard.bool(forKey: "promptedBank"){
                self.addBankBalloonPopUp(product: self.loadedProducts.first)
                UserDefaults.standard.set(true, forKey: "promptedBank")
            }
        case 2:
            SKStoreReviewController.requestReview()
        default:
            return
        }
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
        guard let uid = pUserInfo.uid else{return}

        var localLoaded: [Product]! = [Product]()

        
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(uid).collection("Products").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 12).order(by: "Timestamp", descending: true)
        }
        else if let last = fromInterval{
            query = Firestore.firestore().collection("Users").document(uid).collection("Products").whereField("Timestamp", isLessThan: Timestamp(date: last)).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 12).order(by: "Timestamp", descending: true)
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
                        self.loadedProducts.removeAll()
                        self.offsets.removeAll()
                        self.loadedProducts.removeOldFeedPosts(newPosts: nil)
                        self.loadedProducts.removeAllObjects(type: "Products")
                        completed(false)
                    }
                    else{
                        completed(false)
                    }
                }
                else{
                    
                    guard let snaps = snapDocuments?.documents else {
                        completed(false)
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
                            let isPublic = snap["Public"] as? Bool ?? true
                            let productType = snap["Type"] as? String ?? defaultProductType
                            let displaySide = snap["Side"] as? String ?? "front"
                            let sides = snap["Sides"] as? [String] ?? ["Front"]

                            localLoaded.append(Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description,  productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: pUserInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: isPublic, productType: productType, displaySide: displaySide, supportedSides: sides))
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
                
                guard let userUID = pUserInfo.uid else{return}
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
                    
                    productsToUse.append(product)
           
                    if productsToUse.count == products.count{
                        
                        UserDefaults.standard.set(pUserInfo.userLiked, forKey: "LikedPosts")
                        let sorted = productsToUse.sorted(by: {$0.timestamp > $1.timestamp})
                        for product in sorted{
                            self.loadedProducts.append(product)
                            self.collectionView.performBatchUpdates({
                                self.collectionView.insertItems(at: [IndexPath(row: self.loadedProducts.count - 1, section: 0)])
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

    
    /*
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
 */
    
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
            listVC.listType = header.selectedList
            listVC.user = pUserInfo
        }
        else if let friendVC = segue.destination as? FriendVC{
            friendVC.friendInfo = selectedUser
        }
        else if let designVC = (segue.destination as? UINavigationController)?.viewControllers.first as? DesignInfoViewController{
            
            var designs = [Design]()
            guard let sameTemplate = all.tees.first(where: {$0.productCode == productToOpen.productType}) else{return}
            for side in productToOpen.supportedSides{
                
                var design: Design!
                if side == "Front"{
                    guard let img = cache.imageFromCache(forKey: productToOpen.productID)?.pngData(), let side = sameTemplate.supportedSides.first(where: {$0.name == side}) else{return}
                    design = Design(img: img, side: side)
                }
                else{
                    guard let img = cache.imageFromCache(forKey: "\(side)_\(productToOpen.productID)")?.pngData(), let side = sameTemplate.supportedSides.first(where: {$0.name == side}) else{return}
                    design = Design(img: img, side: side)
                }
                designs.append(design)
            }
            
            designVC.product = ProductInProgress(templateColor: productToOpen.templateColor, designs: designs, uid: productToOpen.userInfo.uid, caption: productToOpen.description, name: productToOpen.name, price: productToOpen.price, productID: productToOpen.productID, display: productToOpen.designImage, isPublic: productToOpen.isPublic, productType: productToOpen.productType, displaySide: productToOpen.displaySide)
            designVC.isEditingProduct = true
        }
        else if let colorSectionVC = segue.destination as? ColorSectionVC{
            colorSectionVC.hashtag = hashtagToOpen
        }
    }
}



extension UIViewController{
    
    func setUserInfo(username: String?, fullname: String?, image: Data?, bio: String?, notifID: String?, dpUID: String?, userFollowing: [String]?, followerCount: Int?, postCount: Int?, followingCount: Int?, usersBlocking: [String]?, verified: Bool){
        
        UserDefaults.standard.set(username, forKey: "USERNAME")
        pUserInfo.username = username
        
        UserDefaults.standard.set(fullname, forKey: "FULLNAME")
        pUserInfo.fullName = fullname
        
        UserDefaults.standard.set(bio, forKey: "BIO")
        pUserInfo.bio = bio
        
        UserDefaults.standard.set(notifID, forKey: "NOTIF_ID")
        pUserInfo.notifID = notifID
        
        UserDefaults.standard.set(userFollowing, forKey: "FOLLOWING")
        pUserInfo.userFollowing = userFollowing ?? []
        
        UserDefaults.standard.set(followerCount, forKey: "FOLLOWER_COUNT")
        pUserInfo.followerCount = followerCount ?? 0
        
        UserDefaults.standard.set(postCount, forKey: "POST_COUNT")
        pUserInfo.postCount = postCount ?? 0
        
        UserDefaults.standard.set(followingCount, forKey: "FOLLOWING_COUNT")
        pUserInfo.followingCount = followingCount ?? 0
        
        UserDefaults.standard.set(followingCount, forKey: "BLOCKING")
        pUserInfo.usersBlocking = usersBlocking ?? []
        
        UserDefaults.standard.set(verified, forKey: "VERIFIED")
        pUserInfo.verified = verified
        
        UserDefaults.standard.set(dpUID, forKey: "DP_ID")
        pUserInfo.dpID = dpUID
        guard let img = image ?? defaultDP else{
            return}
        pUserInfo.dp = img
        SDImageCache.shared.storeImageData(toDisk: img, forKey: dpUID)
    }
}

extension UserVC{
    
    @objc func startBalloon(){

        let bubbleImageView = UIImageView()
        
        let intRandom = self.generateIntRandomNumber(min: 1, max: 6)
        
        bubbleImageView.image = UIImage(named: "balloon")

        if intRandom % 5 == 0{
            bubbleImageView.tintColor = UIColor(red: 0.6902, green: 0.9569, blue: 0.698, alpha: 1.0) /* #b0f4b2 */

        }
        else if intRandom % 2 == 0{
            let color = UIColor(red: 0.5098, green: 0.9176, blue: 1, alpha: 1.0) /* #82eaff */
            bubbleImageView.tintColor = color
        }
        else{
            bubbleImageView.tintColor = UIColor(red: 1, green: 0.7176, blue: 0.7176, alpha: 1.0) /* #ffb7b7 */
        }
                
        let size = self.randomFloatBetweenNumbers(firstNum: 40, secondNum: 75)
        
        let randomOriginX = self.randomFloatBetweenNumbers(firstNum: self.view.frame.minX, secondNum: self.view.frame.maxX)
        let originy = self.view.frame.maxY - 35
        
        bubbleImageView.frame = CGRect(x: randomOriginX, y: originy, width: CGFloat(size), height: CGFloat(size))
        bubbleImageView.alpha = 0.9
        bubbleImageView.layer.cornerRadius = bubbleImageView.frame.size.height / 2
        bubbleImageView.contentMode = .scaleAspectFill
        bubbleImageView.clipsToBounds = true
        self.view.addSubview(bubbleImageView)
        let zigzagPath: UIBezierPath = UIBezierPath()
        let oX: CGFloat = bubbleImageView.frame.origin.x
        let oY: CGFloat = bubbleImageView.frame.origin.y
        let eX: CGFloat = oX
        let eY: CGFloat = oY - (self.randomFloatBetweenNumbers(firstNum: self.view.frame.midY, secondNum: self.view.frame.maxY))
        let t = self.randomFloatBetweenNumbers(firstNum: 20, secondNum: 100)
        var cp1 = CGPoint(x: oX - t, y: ((oY + eY) / 2))
        var cp2 = CGPoint(x: oX + t, y: cp1.y)
        
        let r = arc4random() % 2
        if (r == 1){
            let temp:CGPoint = cp1
            cp1 = cp2
            cp2 = temp
        }
        
        zigzagPath.move(to: CGPoint(x: oX, y: oY))
        
        zigzagPath.addCurve(to: CGPoint(x: eX, y: eY), controlPoint1: cp1, controlPoint2: cp2)
        CATransaction.begin()
        CATransaction.setCompletionBlock({() -> Void in
            
            UIView.transition(with: bubbleImageView, duration: 0.1, options: .transitionCrossDissolve, animations: {() -> Void in
                bubbleImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }, completion: {(_ finished: Bool) -> Void in
                bubbleImageView.removeFromSuperview()
            })
        })
        
        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.duration = 3.5
        pathAnimation.path = zigzagPath.cgPath
        
        pathAnimation.fillMode = CAMediaTimingFillMode.forwards
        pathAnimation.isRemovedOnCompletion = false
        bubbleImageView.layer.add(pathAnimation, forKey: "movingAnimation")
        CATransaction.commit()
        
    }
    
    func generateIntRandomNumber(min: Int, max: Int) -> Int {
        let randomNum = Int(arc4random_uniform(UInt32(max) - UInt32(min)) + UInt32(min))
        return randomNum
    }
    
    func randomFloatBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    
    
    
}



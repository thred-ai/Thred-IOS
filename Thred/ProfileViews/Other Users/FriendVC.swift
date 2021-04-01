//
//  FriendVC.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-05.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFunctions
import FirebaseUI
import ColorCompatibility
import Firebase
import FirebaseAnalytics

class FriendVC: UICollectionViewController, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {

    var loadedProducts = [Product]()
    var isLoading = true
    var selectedUser: UserInfo!
    var tokens = [String]()
    var currentproductsJSON: [DocumentSnapshot]? = [DocumentSnapshot]()
    var downloadingProfiles = [String]()
    var productToOpen = Product()
    var hashtagToOpen: Hashtag?
    var friendInfo = UserInfo()
    var selectedChat: GroupChat!
    
    var reportType: ReportLevel!
    var refresher: BouncingTitleRefreshControl!
    var offsets = [CGFloat]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false

        self.navigationController?.delegate = self
        self.navigationController?.navigationBar.layer.shadowColor = nil
        
        refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        collectionView.register(UINib(nibName: "ExploreProductCell", bundle: nil), forCellWithReuseIdentifier: "ExploreProductCell")
        
        collectionView.addSubview(refresher)
        
        

        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage.init()
        
        //
        initialRefresh(onlyDownloadProducts: false)
        
        
    }
    
    func header() -> ProfileHeaderView?{
        let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? ProfileHeaderView
        return view ?? ProfileHeaderView()
    }
    
    func initialRefresh(onlyDownloadProducts: Bool){
        
        self.isLoading = false
        self.refresh(nil)
    }
    
    
    
    
    
    func updateFollowInDatabase(didFollow: Bool){
        guard let uid = pUserInfo.uid else{return}
        guard let friendUID = friendInfo.uid else{return}
        
        if didFollow{
            friendInfo.followerCount += 1
            pUserInfo.userFollowing.append(friendUID)
            UserDefaults.standard.set(pUserInfo.userFollowing, forKey: "FOLLOWING")
            let data = [
                 "UID" : friendUID
             ]
            Analytics.logEvent("followed_another_user", parameters: [
                "name": "Followed User",
                "full_text": "User followed another user"
            ])
            checkAuthStatus {
                Firestore.firestore().document("Users/\(uid)/Following/\(friendUID)").setData(data, completion: { error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        
                    }
                    else{
                       
                       pUserInfo.followingCount += 1
                       UserDefaults.standard.set(pUserInfo.followingCount, forKey: "FOLLOWING_COUNT")
                    }
                })
            }
        }
        else{
            friendInfo.followerCount -= 1
            pUserInfo.userFollowing.removeAll(where: {$0 == friendUID})
            UserDefaults.standard.set(pUserInfo.userFollowing, forKey: "FOLLOWING")
            Analytics.logEvent("unfollowed_another_user", parameters: [
                "name": "Unfollowed User",
                "full_text": "User unfollowed another user"
            ])
            Firestore.firestore().collection("Users/\(uid)/Following").document(friendUID).delete(
                completion: { error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                }
                else{
                    pUserInfo.followingCount -= 1
                    UserDefaults.standard.set(pUserInfo.followingCount, forKey: "FOLLOWING_COUNT")
                }
            })
        }
        header()?.followerNum?.text = "\(friendInfo.followerCount)"
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind{
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerCell", for: indexPath) as? ProfileHeaderView
            var title = view?.headerActionBtnTitle
            if isBlocking() ?? false{
                title = "User Blocked"
            }
            view?.setUpInfo(username: friendInfo.username ?? "", fullname: friendInfo.fullName ?? "", bio: friendInfo.bio ?? "", notifID: friendInfo.notifID, dpUID: nil, image: friendInfo.dp, actionBtnTitle: title ?? "", followerCount: friendInfo.followerCount, followingCount: friendInfo.followingCount, postCount: friendInfo.postCount, verified: friendInfo.verified)
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if loadedProducts.isEmpty{
            return CGSize(width: collectionView.frame.width, height: 120)
        }
        else{
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func isBlocking() -> Bool?{
        guard let userUID = pUserInfo.uid else{return nil}
        if !(friendInfo.usersBlocking.contains(userUID)){
            return false
        }
        else{
            return true
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = loadedProducts[indexPath.item]
        self.productToOpen = product
        self.performSegue(withIdentifier: "toFull", sender: nil)
    }
    
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
            var timer: DispatchTime = .now()
            if sender != nil{
                timer = .now() + 1
            }
            DispatchQueue.main.asyncAfter(deadline: timer) {
                guard let userUID = pUserInfo.uid else{return}
                self.checkAuthStatus {
                    self.refreshLists(userUID: userUID, onlyBlocking: true){
                        self.downloadUserInfo(uid: self.friendInfo.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: true, doNotDownloadDP: false, userInfoToUse: self.friendInfo, queryOnUsername: self.friendInfo.uid == nil, completed: {
                            
                            uid, fullName, username, dpID, notifID, bio, image, userFollowing, usersBlocking, postNotifs, postCount, followersCount, followingCount, verified in
                            if username != nil{
                                self.setInfo(username: username, fullname: fullName, dpID: dpID, image: image, notifID: notifID, bio: bio, userFollowing: userFollowing, uid: uid, followerCount: followersCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking, postNotifs: postNotifs, verified: verified ?? false)
                                if usersBlocking.contains(userUID){
                                    self.setBlocking()
                                    return
                                }
                                guard let uid = uid else{return}
                                self.header()?.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: self.header()?.headerActionBtnTitle ?? "", followerCount: followersCount, followingCount: followingCount, postCount: postCount, verified: verified ?? false)

                                let isFollowing = pUserInfo.userFollowing.contains(uid)
                                print(pUserInfo)
                                print(isFollowing)
                                
                                self.header()?.updateFollowBtn(didFollow: isFollowing, animated: false)

                                self.downloadProducts(){
                                    self.isLoading = false
                                    if sender?.isRefreshing ?? false{
                                        sender?.endRefreshing()
                                    }
                                }
                                self.collectionView.performBatchUpdates({
                                    self.collectionView.reloadItems(at: self.collectionView?.indexPathsForVisibleItems ?? [])
                                }, completion: { complete in
                                    if complete{
                                    }
                                })
                            }
                            else{
                                self.showBlocked()
                            }
                        })
                    }
                }
            }
        }
        else{
            sender?.endRefreshing()
        }
    }
    
    func showBlocked(){
        self.header()?.clearAll(actionBtnTitle: "User not found")
        self.collectionView.refreshControl = nil
        refresher.removeFromSuperview()
        self.collectionView.alwaysBounceVertical = false
        self.header()?.isUserInteractionEnabled = false
        self.isLoading = false
        self.collectionView.reloadData()
    }
    
    func setInfo(username: String?, fullname: String?, dpID: String?, image: Data?, notifID: String?, bio: String?, userFollowing: [String], uid: String?, followerCount: Int, postCount: Int, followingCount: Int, usersBlocking: [String], postNotifs: [String], verified: Bool){
        
        guard let username = username else{
            
            return}
        guard let fullname = fullname else{
            
            return}
        guard let dpID = dpID else{
            
            return}
        guard let bio = bio else{
            
            return}
        guard let uid = uid else{
            
            return}
        
        friendInfo.username = username
        friendInfo.fullName = fullname
        friendInfo.dpID = dpID
        friendInfo.bio = bio
        friendInfo.userFollowing = userFollowing
        friendInfo.postNotifsList = postNotifs
        friendInfo.uid = uid
        friendInfo.followerCount = followerCount
        friendInfo.followingCount = followingCount
        friendInfo.postCount = postCount
        friendInfo.usersBlocking = usersBlocking
        friendInfo.verified = verified
        guard let img = image else{return}
        friendInfo.dp = img
    }
    
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let feed = viewController as? FeedVC{
            feed.selectedUser = self.friendInfo
        }
    }
    
    func downloadProducts(completed: @escaping () -> ()){
        self.getProducts(fromInterval: nil) { hasDiffproducts, snapDocs in
            completed()
            if hasDiffproducts ?? false{
                self.currentproductsJSON = snapDocs
                if !self.loadedProducts.isEmpty{
                    self.loadedProducts.removeAll()
                    self.collectionView.reloadData()
                }
            }
            else{
                if self.loadedProducts.isEmpty{
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    var lastDoc: DocumentSnapshot!
    
    func getProducts(fromInterval: Date?, completed: @escaping (Bool?, [DocumentSnapshot]?) -> ()){
           
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
        guard let friendUID = friendInfo.uid else{return}
        guard let userUID = pUserInfo.uid else{return}
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(friendUID).collection("Products").whereField("Public", isEqualTo: true).whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 12).order(by: "Timestamp", descending: true)
        }
        else if let lastDoc = lastDoc{
            query = Firestore.firestore().collection("Users").document(friendUID).collection("Products").whereField("Public", isEqualTo: true).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 12).order(by: "Timestamp", descending: true).start(afterDocument: lastDoc)
        }
        query.getDocuments(completion: { (snapDocuments, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                
                completed(false, nil)
                return
            }
            else if snapDocuments?.isEmpty ?? true{
                completed(false, nil)
            }
            else {
                
                switch fromInterval{
                case .none:
                    if self.currentproductsJSON == snapDocuments?.documents{
                        completed(false, nil)
                        return
                    }
                    else{
                        fallthrough
                    }
                default:
                    guard let snaps = snapDocuments?.documents else {return}
                    self.lastDoc = snaps.last
                    completed(true, snaps)
                    var productsToUse: [Product]! = [Product]()
                    for (index, snap) in snaps.enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
                        if !self.loadedProducts.contains(where: {$0.productID == snap.documentID}){
                            
                            let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                            let uid = snap["UID"] as! String
                            let description = snap["Description"] as? String
                            let name = snap["Name"] as? String
                            let blurred = snap["Blurred"] as? Bool
                            let templateColor = snap["Template_Color"] as? String
                            let likes = snap["Likes"] as? Int
                            guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                            let comments = ((snap["Comments"]) as? Int) ?? 0
                            let productType = snap["Type"] as? String ?? defaultProductType
                            let displaySide = snap["Side"] as? String ?? "front"
                            let sides = snap["Sides"] as? [String] ?? ["Front"]

                            Firestore.firestore().collection("Users").document(friendUID).collection("Products").document(snap.documentID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                            
                                var liked: Bool!
                                
                                if error != nil{
                                    print(error?.localizedDescription ?? "")
                                }
                                else{
                                    pUserInfo.userLiked.removeAll(where: {$0 == snap.documentID})
                                    if let likeDocs = snapLikes?.documents{
                                        if likeDocs.isEmpty{
                                            liked = false
                                        }
                                        else{
                                            liked = true
                                            if !(pUserInfo.userLiked.contains(snap.documentID)){
                                                pUserInfo.userLiked.append(snap.documentID)
                                            }
                                        }
                                    }
                                    else{
                                        liked = false
                                    }
                                }
                                
                                let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true, productType: productType, displaySide: displaySide, supportedSides: sides)
                                
                                productsToUse.append(product)
                                
                                if productsToUse.count == (snaps.count){
                                    UserDefaults.standard.set(pUserInfo.userLiked, forKey: "LikedPosts")
                                    let sorted = productsToUse.sorted(by: {$0.timestamp > $1.timestamp})
                                    for product in sorted{
                                        self.loadedProducts.append(product)
                                        
                                        self.collectionView.performBatchUpdates({
                                            self.collectionView.insertItems(at: [IndexPath(row: self.loadedProducts.count - 1, section: 0)])
                                        }, completion: { finished in
                                            if finished{
                                                if product == sorted.last{
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
            }
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.loadedProducts.count
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
    
    
    lazy var headerView: UICollectionReusableView? = {
        
        return loadProfilePostHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    /*
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if loadedProducts.isEmpty{
            return 150
        }
        return 0
    }
       
 */
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.size.height) / 2{
            print("fromScroll")
            if let last = self.loadedProducts.last{
                
                if let interval = last.timestamp{
                    
                    if !self.isLoading, canLoadMore{
                        self.isLoading = true
                        self.getProducts(fromInterval: interval){ _,_ in
                            self.isLoading = false
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
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let viewControllers = navigationController?.viewControllers, let index = viewControllers.firstIndex(of: self){
            if !(viewControllers[index - 1] is FullProductVC || viewControllers[index - 1] is SalesVC || viewControllers[index - 1] is CommentsVC || viewControllers[index - 1] is UserListVC || viewControllers[index - 1] is ChatVC){
                showCenterBtn()
            }
        }
        //tableView.syncPostLikes(loadedProducts: loadedProducts, vc: self)
    }


    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
     
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    var optionMenuActionBtn1: UIButton!
    var optionMenuActionBtn2: UIButton!
    var optionMenuCancelBtn: UIButton!
    
    func setBlocking(){
        
        self.header()?.headerActionBtnTitle = "User Blocked"
        self.header()?.actionBtn?.isUserInteractionEnabled = false
        self.loadedProducts.removeAll()
        self.collectionView.reloadData()
        self.currentproductsJSON = nil
        isLoading = false
    }
    
    
    func setUnblocking(){

        self.friendInfo.usersBlocking.removeAll()
        print(friendInfo.usersBlocking)
        
        self.header()?.updateFollowBtn(didFollow: false, animated: true)
        self.header()?.actionBtn?.isUserInteractionEnabled = true
        self.collectionView.reloadData()
        self.refresh(nil)
    }
    
    @objc func blockUser(_ sender: UIButton?){
        
        guard let uid = pUserInfo.uid else{
            
            return}
        guard let friendUID = friendInfo.uid else{
            
            return}
        let isBlocking = !(friendInfo.usersBlocking.contains(uid))
        let isFollowing = pUserInfo.userFollowing.contains(friendUID)
        let isFollower = friendInfo.userFollowing.contains(uid)

        print(isBlocking)
        print(friendInfo.usersBlocking)
        
        if isBlocking{
            self.friendInfo.usersBlocking.append(uid)

            setBlocking()
            
            if isFollowing{
                self.header()?.followerNum?.text = "\(self.friendInfo.followerCount - 1)"
                pUserInfo.followingCount -= 1
                UserDefaults.standard.set(pUserInfo.followingCount, forKey: "FOLLOWING_COUNT")
                pUserInfo.userFollowing.removeAll(where: {$0 == friendUID})
                UserDefaults.standard.set(pUserInfo.userFollowing, forKey: "FOLLOWING")
            }
            if isFollower{
                self.header()?.followingNum?.text = "\(self.friendInfo.followingCount - 1)"
                pUserInfo.followingCount -= 1
                UserDefaults.standard.set(pUserInfo.followingCount, forKey: "FOLLOWER_COUNT")
            }
        }
        else{
            setUnblocking()
        }
        

        let data = [
            "isBlocking" : isBlocking,
            "uid" : uid,
            "blockingUID" : friendUID,
            "isFollowing" : isFollowing,
            "isFollower" : isFollower
        ] as [String : Any]
        
        checkAuthStatus {
            Functions.functions().httpsCallable("blockOrUnblock").call(data, completion: { result, error in
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                   
                }
            })
        }
    }
    
    @objc func changePostNotifs(_ sender: UIButton?){
        
        guard let uid = pUserInfo.uid else{
            
            return}
        guard let friendUID = friendInfo.uid else{
            
            return}
        let isSettingNotif = !(friendInfo.postNotifsList.contains(uid))

        if isSettingNotif{
            self.friendInfo.postNotifsList.append(uid)
        }
        else{
            self.friendInfo.postNotifsList.removeAll(where: {$0 == uid})
        }
        

        let data = [
            "setNotif" : isSettingNotif,
            "uid" : uid,
            "friendUID" : friendUID
        ] as [String : Any]
        
        checkAuthStatus {
            Functions.functions().httpsCallable("setPostNotifs").call(data, completion: { result, error in
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                   
                }
            })
        }
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
    }

    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        optionMenuActionBtn1?.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        optionMenuActionBtn2?.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        optionMenuCancelBtn?.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor

    }
    
    
    var selectedReportID: String!
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
            listVC.listType = header()?.selectedList
            listVC.user = friendInfo
        }
        else if let friendVC = segue.destination as? FriendVC{
            friendVC.friendInfo = selectedUser
        }
        else if let reportVC = (segue.destination as? UINavigationController)?.viewControllers.first as? ReportVC{
            reportVC.reportLevel = reportType
            if reportType == .post{
                reportVC.reportPostID = selectedReportID
            }
            reportVC.reportUID = friendInfo.uid
        }
        else if let colorSectionVC = segue.destination as? ColorSectionVC{
            colorSectionVC.hashtag = hashtagToOpen
        }
        else if let chatVC = segue.destination as? ChatVC{
            chatVC.chatInfo = selectedChat
        }
    }

}

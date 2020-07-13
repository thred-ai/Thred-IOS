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


class FriendVC: UITableViewController, UINavigationControllerDelegate {

    var loadedProducts = [Product]()
    var isLoading = true
    var selectedUser: UserInfo!
    var tokens = [String]()
    var currentproductsJSON: [DocumentSnapshot]? = [DocumentSnapshot]()
    var downloadingProfiles = [String]()
    var productToOpen = Product()
    var friendInfo = UserInfo()
    var header: ProfileHeaderView?
    var reportType: ReportLevel!
    var refresher: BouncingTitleRefreshControl!
    var offsets = [CGFloat]()

    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ProductCell{
            if offsets.indices.contains(indexPath.row){
                offsets[indexPath.row] = cell.collectionViewOffset
            }
            else{
                offsets.append(cell.collectionViewOffset)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false

        self.navigationController?.delegate = self
        self.navigationController?.navigationBar.layer.shadowColor = nil
        
        refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.allowsSelection = false
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")

        header = tableView.loadUserHeaderFromNib()
        tableView.addSubview(refresher)
        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage.init()

        header?.actionBtn.addTarget(self, action: #selector(followBtnPressed(_:)), for: .touchUpInside)
        header?.actionBtn.isUserInteractionEnabled = true
        header?.optionBtn.setImage(UIImage(nameOrSystemName: "ellipsis.circle", systemPointSize: 20, iconSize: 7), for: .normal)
        header?.optionBtn.addTarget(self, action: #selector(openOptionMenu(_:)), for: .touchUpInside)
        initialRefresh(onlyDownloadProducts: false)
    }
    
    func initialRefresh(onlyDownloadProducts: Bool){
        if updateForBlocking() ?? false{
            return
        }
        self.header?.setUpInfo(username: friendInfo.username ?? "", fullname: friendInfo.fullName ?? "", bio: friendInfo.bio ?? "", notifID: friendInfo.notifID, dpUID: nil, image: friendInfo.dp, actionBtnTitle: header?.headerActionBtnTitle ?? "null", followerCount: friendInfo.followerCount, followingCount: friendInfo.followingCount, postCount: friendInfo.postCount)

        if friendInfo.dp != nil{
            switch onlyDownloadProducts{
            case false:
                if let vcIndex = navigationController?.viewControllers.firstIndex(of: self){
                    if navigationController?.viewControllers[vcIndex - 1] is FullProductVC || navigationController?.viewControllers[vcIndex - 1] is FeedVC{
                        self.isLoading = false
                        self.refresh(refresher)
                    }
                    else{
                        fallthrough
                    }
                }
            default:
                guard let friendUID = friendInfo.uid else{return}
                guard let uid = userInfo.uid else{return}
                let isFollowing = (userInfo.userFollowing.contains(friendUID))
                header?.updateFollowBtn(didFollow: isFollowing, animated: false)
                header?.actionBtn.isUserInteractionEnabled = true
                refreshLists(userUID: uid){
                    if userInfo.usersBlocking.contains(friendUID){
                        self.showBlocked()
                        return
                    }
                    self.downloadProducts(){
                        self.isLoading = false
                    }
                }
            }
        }
        else{
            self.isLoading = false
            self.refresh(refresher)
        }
    }
    
    
    
    @objc func followBtnPressed(_ sender: UIButton){
        
        let following = userInfo.userFollowing
        guard let uid = friendInfo.uid else{
            return}
        let didFollow = !following.contains(uid)
        header?.updateFollowBtn(didFollow: didFollow, animated: true)
        updateFollowInDatabase(didFollow: didFollow)
    }
    
    func updateFollowInDatabase(didFollow: Bool){
        guard let uid = userInfo.uid else{return}
        guard let friendUID = friendInfo.uid else{return}
        
        if didFollow{
            friendInfo.followerCount += 1
            userInfo.userFollowing.append(friendUID)
            UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
            let data = [
                 "UID" : friendUID
             ]
            checkAuthStatus {
                Firestore.firestore().document("Users/\(uid)/Following/\(friendUID)").setData(data, completion: { error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                       
                       userInfo.followingCount += 1
                       UserDefaults.standard.set(userInfo.followingCount, forKey: "FOLLOWING_COUNT")
                    }
                })
            }
        }
        else{
            friendInfo.followerCount -= 1
            userInfo.userFollowing.removeAll(where: {$0 == friendUID})
            UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
            Firestore.firestore().collection("Users/\(uid)/Following").document(friendUID).delete(
                completion: { error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                }
                else{
                    userInfo.followingCount -= 1
                    UserDefaults.standard.set(userInfo.followingCount, forKey: "FOLLOWING_COUNT")
                }
            })
        }
        header?.followerNum.text = "\(friendInfo.followerCount)"
    }
    
    func updateForBlocking() -> Bool?{
        guard let userUID = userInfo.uid else{return nil}
        if !(friendInfo.usersBlocking.contains(userUID)){
            return nil
        }
        else{
            self.header?.clearAll(actionBtnTitle: "User Blocked")
            self.header?.actionBtn.isUserInteractionEnabled = false
            self.loadedProducts.removeAll()
            self.tableView.reloadData()
            self.currentproductsJSON = nil
            isLoading = false
            return true
        }
    }
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
        
        if updateForBlocking() ?? false{
            sender.endRefreshing()
            return
        }
        
        guard checkInternetConnection() else{
            sender.endRefreshing()
            return
        }
        
        if !isLoading{
            isLoading = true
            if sender.isRefreshing{
                sender.animateRefresh()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard let userUID = userInfo.uid else{return}
                self.checkAuthStatus {
                    self.refreshLists(userUID: userUID){
                        self.downloadUserInfo(uid: self.friendInfo.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: true, doNotDownloadDP: false, userInfoToUse: self.friendInfo, queryOnUsername: self.friendInfo.uid == nil, completed: {
                            uid, fullName, username, dpID, notifID, bio, image, userFollowing, usersBlocking, postCount, followersCount, followingCount in
                            if username != nil{
                                self.setInfo(username: username, fullname: fullName, dpID: dpID, image: image, notifID: notifID, bio: bio, userFollowing: userFollowing, uid: uid, followerCount: followersCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking)
                                if self.updateForBlocking() ?? false{
                                    return
                                }
                                guard let uid = self.friendInfo.uid else{return}
                                let isFollowing = (userInfo.userFollowing.contains(uid))
                                self.header?.updateFollowBtn(didFollow: isFollowing, animated: false)
                                self.header?.actionBtn.isUserInteractionEnabled = true
                                self.header?.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: self.header?.headerActionBtnTitle ?? "null", followerCount: followersCount, followingCount: followingCount, postCount: postCount)

                                self.downloadProducts(){[weak self] in
                                    self?.isLoading = false
                                    if sender.isRefreshing{
                                        sender.endRefreshing()
                                    }
                                }
                                self.tableView.performBatchUpdates({
                                    self.tableView.reloadRows(at: self.tableView?.indexPathsForVisibleRows ?? [], with: .automatic)
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
            sender.endRefreshing()
        }
    }
    
    func showBlocked(){
        self.header?.clearAll(actionBtnTitle: "User not found")
        self.tableView.refreshControl = nil
        refresher.removeFromSuperview()
        self.tableView.alwaysBounceVertical = false
        self.header?.isUserInteractionEnabled = false
        self.isLoading = false
        self.tableView.reloadData()
    }
    
    func setInfo(username: String?, fullname: String?, dpID: String?, image: Data?, notifID: String?, bio: String?, userFollowing: [String], uid: String?, followerCount: Int, postCount: Int, followingCount: Int, usersBlocking: [String]){
        
        guard let username = username else{return}
        guard let fullname = fullname else{return}
        guard let dpID = dpID else{return}
        guard let bio = bio else{return}
        guard let uid = uid else{
            
            return}

        
        friendInfo.username = username
        friendInfo.fullName = fullname
        friendInfo.dpID = dpID
        friendInfo.bio = bio
        friendInfo.userFollowing = userFollowing
        friendInfo.uid = uid
        friendInfo.followerCount = followerCount
        friendInfo.followingCount = followingCount
        friendInfo.postCount = postCount
        friendInfo.usersBlocking = usersBlocking
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
                    self.cellHeights.removeAll()
                    self.offsets.removeAll()
                    for cell in (self.tableView.visibleCells as! [ProductCell]){
                        cell.collectionViewOffset = 0
                    }
                    self.tableView.reloadData()
                }
            }
            else{
                if self.loadedProducts.isEmpty{
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
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
        guard let userUID = userInfo.uid else{return}
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(friendUID).collection("Products").whereField("Public", isEqualTo: true).whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        else if let lastDoc = lastDoc{
            query = Firestore.firestore().collection("Users").document(friendUID).collection("Products").whereField("Public", isEqualTo: true).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true).start(afterDocument: lastDoc)
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

                            Firestore.firestore().collection("Users").document(friendUID).collection("Products").document(snap.documentID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                            
                                var liked: Bool!
                                
                                if error != nil{
                                    print(error?.localizedDescription ?? "")
                                }
                                else{
                                    userInfo.userLiked.removeAll(where: {$0 == snap.documentID})
                                    if let likeDocs = snapLikes?.documents{
                                        if likeDocs.isEmpty{
                                            liked = false
                                        }
                                        else{
                                            liked = true
                                            if !(userInfo.userLiked.contains(snap.documentID)){
                                                userInfo.userLiked.append(snap.documentID)
                                            }
                                        }
                                    }
                                    else{
                                        liked = false
                                    }
                                }
                                
                                let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true)
                                
                                productsToUse.append(product)
                                
                                if productsToUse.count == (snaps.count){
                                    UserDefaults.standard.set(userInfo.userLiked, forKey: "LikedPosts")
                                    let sorted = productsToUse.sorted(by: {$0.timestamp > $1.timestamp})
                                    for product in sorted{
                                        self.loadedProducts.append(product)
                                        
                                        self.tableView.performBatchUpdates({
                                            self.tableView.insertRows(at: [IndexPath(row: self.loadedProducts.count - 1, section: 0)], with: .none)
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
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.loadedProducts.count
    }
    
    lazy var headerView: UIView? = {
        
        return loadProfilePostHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if loadedProducts.isEmpty{
            return 150
        }
        return 0
    }
       
    var cellHeights: [IndexPath: CGFloat] = [:]
       
    ///* Dynamic Cell Sizing *///
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 1500
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) / 2{
            print("fromScroll")
            if let last = self.loadedProducts.last{
                
                if let interval = last.timestamp{
                    
                    if !self.isLoading, canLoadMore{
                        self.isLoading = true
                        self.getProducts(fromInterval: interval){ _,_ in
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
    
    
    
    
    
    
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let user = self.loadedProducts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PictureProduct", for: indexPath) as? ProductCell
        tableView.setPictureCell(cell: cell, indexPath: indexPath, product: user, productLocation: self, shouldDownloadPic: true)
        return cell!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let viewControllers = navigationController?.viewControllers, let index = viewControllers.firstIndex(of: self){
            if !(viewControllers[index - 1] is FullProductVC || viewControllers[index - 1] is SalesVC || viewControllers[index - 1] is CommentsVC){
                showCenterBtn()
            }
        }
        tableView.syncPostLikes(loadedProducts: loadedProducts, vc: self)
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
    
    lazy var optionMenu: UIView = {
        
        guard let header = self.header else{return UIView()}
        let view = UIView(frame: header.bounds)
        
        //view.translatesAutoresizingMaskIntoConstraints = false
       
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)

        let stackView = UIStackView.init(frame: view.bounds)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        //stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonSize = 75
        
        let optionMenuView1 = UIView.init(frame: CGRect(x: 0, y:0, width: stackView.frame.width / 3, height: stackView.frame.height))
        
        optionMenuActionBtn1 = UIButton.init(frame: CGRect(x: 0, y:0, width: buttonSize, height: buttonSize))
        optionMenuActionBtn1.setTitle("Report", for: .normal)
        optionMenuActionBtn1.backgroundColor = .tertiarySystemFill
        optionMenuActionBtn1.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        optionMenuActionBtn1.layer.cornerRadius = optionMenuActionBtn1.frame.height / 2
        optionMenuActionBtn1.clipsToBounds = true
        optionMenuActionBtn1.center = optionMenuView1.center
        optionMenuActionBtn1.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        optionMenuActionBtn1.layer.borderWidth = optionMenuActionBtn1.frame.height / 17.75
        optionMenuActionBtn1.addTarget(self, action: #selector(reportUser(_:)), for: .touchUpInside)
        optionMenuView1.addSubview(optionMenuActionBtn1)
        
        let optionMenuView2 = UIView.init(frame: CGRect(x: 0, y:0, width: stackView.frame.width / 3, height: stackView.frame.height))
        optionMenuActionBtn2 = UIButton.init(frame: CGRect(x: 0, y:0, width: buttonSize, height: buttonSize))
        optionMenuActionBtn2.setTitle("Block", for: .normal)
        optionMenuActionBtn2.setTitleColor(.red, for: .normal)
        optionMenuActionBtn2.backgroundColor = .tertiarySystemFill
        optionMenuActionBtn2.setTitleColor(.red, for: .normal)
        optionMenuActionBtn2.layer.cornerRadius = optionMenuActionBtn2.frame.height / 2
        optionMenuActionBtn2.clipsToBounds = true
        optionMenuActionBtn2.center = optionMenuView2.center
        optionMenuActionBtn2.addTarget(self, action: #selector(blockUser(_:)), for: .touchUpInside)
        optionMenuActionBtn2.titleLabel?.adjustsFontSizeToFitWidth = true
        optionMenuActionBtn2.titleLabel?.minimumScaleFactor = 0.5
        optionMenuActionBtn2.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        optionMenuActionBtn2.layer.borderWidth = optionMenuActionBtn2.frame.height / 17.75
        optionMenuView2.addSubview(optionMenuActionBtn2)
        
        
        let optionMenuView3 = UIView.init(frame: CGRect(x: 0, y:0, width: stackView.frame.width / 3, height: stackView.frame.height))
        optionMenuCancelBtn = UIButton.init(frame: CGRect(x: 0, y:0, width: buttonSize, height: buttonSize))
        optionMenuCancelBtn.setTitle("Cancel", for: .normal)
        optionMenuCancelBtn.backgroundColor = .tertiarySystemFill
        optionMenuCancelBtn.setTitleColor(.label, for: .normal)
        optionMenuCancelBtn.layer.cornerRadius = optionMenuCancelBtn.frame.height / 2
        optionMenuCancelBtn.clipsToBounds = true
        optionMenuCancelBtn.center = optionMenuView3.center
        optionMenuCancelBtn.addTarget(self, action: #selector(openOptionMenu(_:)), for: .touchUpInside)
        optionMenuCancelBtn.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        optionMenuCancelBtn.layer.borderWidth = optionMenuCancelBtn.frame.height / 17.75
        optionMenuView3.addSubview(optionMenuCancelBtn)
        
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(openOptionMenu(_:)))
        view.addGestureRecognizer(gesture)
        stackView.addArrangedSubview(optionMenuView1)
        stackView.addArrangedSubview(optionMenuView2)
        stackView.addArrangedSubview(optionMenuView3)
        view.addSubview(stackView)
        
    
        
        
        return view
    }()
    
    @objc func blockUser(_ sender: UIButton){
        
        guard let uid = userInfo.uid else{return}
        guard let friendUID = friendInfo.uid else{return}
        let isBlocking = !(friendInfo.usersBlocking.contains(uid))
        let isFollowing = userInfo.userFollowing.contains(friendUID)
        let isFollower = friendInfo.userFollowing.contains(uid)

        self.openOptionMenu(nil)
        if isBlocking{
            self.friendInfo.usersBlocking.append(uid)
            let _ = self.updateForBlocking()
            if isFollowing{
                self.header?.followerNum.text = "\(self.friendInfo.followerCount - 1)"
                userInfo.followingCount -= 1
                UserDefaults.standard.set(userInfo.followingCount, forKey: "FOLLOWING_COUNT")
                userInfo.userFollowing.removeAll(where: {$0 == friendUID})
                UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
            }
            if isFollower{
                self.header?.followingNum.text = "\(self.friendInfo.followingCount - 1)"
                userInfo.followingCount -= 1
                UserDefaults.standard.set(userInfo.followingCount, forKey: "FOLLOWER_COUNT")
            }
        }
        else{
            self.friendInfo.usersBlocking.removeAll(where: {$0 == uid})
            self.header?.updateFollowBtn(didFollow: false, animated: true)
            self.header?.actionBtn.isUserInteractionEnabled = true
            self.initialRefresh(onlyDownloadProducts: true)
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
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if header?.subviews.contains(optionMenu) ?? false{
            openOptionMenu(nil)
        }
    }
    
    @objc func reportUser(_ sender: UIButton){
        reportType = .profile
        openOptionMenu(nil)
        self.performSegue(withIdentifier: "toReport", sender: nil)
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        optionMenuActionBtn1?.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        optionMenuActionBtn2?.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        optionMenuCancelBtn?.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor

    }
    
    
    
    @objc func openOptionMenu(_ sender: UIButton?) {
        
        guard let header = self.header else{return}
        guard let uid = userInfo.uid else{return}
        if !header.subviews.contains(optionMenu){
            header.addSubview(optionMenu)
            if friendInfo.usersBlocking.contains(uid){
                optionMenuActionBtn2.setTitle("Unblock", for: .normal)
            }
            else{
                optionMenuActionBtn2.setTitle("Block", for: .normal)
            }

            tableView?.isScrollEnabled = false
            optionMenu.isHidden = false
            optionMenu.alpha = 0.0
            UIView.animate(withDuration: 0.1, animations: {
                self.optionMenu.alpha = 1.0
            }, completion: {finished in
                
            })
        }
        else{
            tableView?.isScrollEnabled = true
            optionMenu.removeFromSuperview()
        }
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
            listVC.listType = header?.selectedList
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
    }

}

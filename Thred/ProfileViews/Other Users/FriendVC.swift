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
    var isLoading = Bool()
    var downloader: SDWebImageDownloader? = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)

    var tokens = [String]()
    var currentproductsJSON: [DocumentSnapshot]? = [DocumentSnapshot]()
    var downloadingProfiles = [String]()
    var productToOpen = Product()
    var friendInfo = UserInfo()
    var header: ProfileHeaderView?
    var reportType: ReportLevel!
    var refresher: BouncingTitleRefreshControl!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false

        self.navigationController?.delegate = self
        self.navigationController?.navigationBar.layer.shadowColor = nil
        
        refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")

        self.header = self.tableView.loadUserHeaderFromNib()
        self.tableView.addSubview(refresher)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage.init()

        self.header?.clearAll(actionBtnTitle: header?.headerActionBtnTitle ?? "null")
        header?.actionBtn.addTarget(self, action: #selector(followBtnPressed(_:)), for: .touchUpInside)
        self.header?.actionBtn.isUserInteractionEnabled = true
        header?.optionBtn.setImage(UIImage(nameOrSystemName: "ellipsis.circle", systemPointSize: 20, iconSize: 7), for: .normal)
        header?.optionBtn.addTarget(self, action: #selector(openOptionMenu(_:)), for: .touchUpInside)

        initialRefresh(onlyDownloadProducts: false)
    }
    
    func initialRefresh(onlyDownloadProducts: Bool){
        if updateForBlocking() ?? false{
            return
        }
        if let image = friendInfo.dp{
            
            self.header?.setUpInfo(username: friendInfo.username, fullname: friendInfo.fullName, bio: friendInfo.bio, notifID: friendInfo.notifID, dpUID: nil, image: image, actionBtnTitle: header?.headerActionBtnTitle ?? "null", followerCount: friendInfo.followerCount ?? 0, followingCount: friendInfo.followingCount ?? 0, postCount: friendInfo.postCount ?? 0)
            switch onlyDownloadProducts{
            case false:
                if let vcIndex = navigationController?.viewControllers.firstIndex(of: self){
                    if navigationController?.viewControllers[vcIndex - 1] is FullProductVC || navigationController?.viewControllers[vcIndex - 1] is FeedVC{
                        self.refresh(refresher)
                    }
                    else{
                        fallthrough
                    }
                }
            default:
                guard let uid = friendInfo.uid else{return}
                let isFollowing = (userInfo.userFollowing.contains(uid))
                header?.updateFollowBtn(didFollow: isFollowing, animated: false)
                self.header?.actionBtn.isUserInteractionEnabled = true
                self.downloadProducts(){
                    return
                }
            }
        }
        else{
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
            friendInfo.followerCount! += 1
            let data = [
                 "UID" : friendUID
             ]
            Firestore.firestore().document("Users/\(uid)/Following/\(friendUID)").setData(data, completion: { error in
                 if error != nil{
                     print(error?.localizedDescription ?? "")
                 }
                 else{
                    
                    guard var followingCount = userInfo.followingCount else{return}
                    followingCount += 1
                    UserDefaults.standard.set(followingCount, forKey: "FOLLOWING_COUNT")
                    userInfo.userFollowing.append(friendUID)
                    UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
                 }
             })
        }
        else{
            friendInfo.followerCount! -= 1
            Firestore.firestore().collection("Users/\(uid)/Following").document(friendUID).delete(
                completion: { error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                }
                else{
                    guard var followingCount = userInfo.followingCount else{return}
                    followingCount -= 1
                    UserDefaults.standard.set(followingCount, forKey: "FOLLOWING_COUNT")
                    userInfo.userFollowing.removeAll(where: {$0 == friendUID})
                    UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
                }
            })
        }
        header?.followerNum.text = "\(friendInfo.followerCount!)"
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
        
        if !isLoading{
            isLoading = true
            if sender.isRefreshing{
                sender.animateRefresh()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.downloader == nil{
                    self.downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
                }
                self.downloader?.cancelAllDownloads()
                guard let userUID = userInfo.uid else{return}
                self.refreshLists(userUID: userUID){
                    self.downloadUserInfo(uid: self.friendInfo.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: true, doNotDownloadDP: false, downloader: self.downloader, userInfoToUse: self.friendInfo, queryOnUsername: self.friendInfo.uid == nil, completed: {
                        uid, fullName, username, dpID, notifID, bio, image, userFollowing, usersBlocking, postCount, followersCount, followingCount  in
                        if username != nil{
                            self.setInfo(username: username, fullname: fullName, dpID: dpID, image: image, notifID: notifID, bio: bio, userFollowing: userFollowing, uid: uid, followerCount: followersCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking)
                            if self.updateForBlocking() ?? false{
                                return
                            }
                            guard let uid = self.friendInfo.uid else{return}
                            let isFollowing = (userInfo.userFollowing.contains(uid))
                            self.header?.updateFollowBtn(didFollow: isFollowing, animated: false)
                            self.header?.actionBtn.isUserInteractionEnabled = true
                            self.header?.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: self.header?.headerActionBtnTitle ?? "null", followerCount: followersCount ?? 0, followingCount: followingCount ?? 0, postCount: postCount ?? 0)

                            self.downloadProducts(){[weak self] in
                                self?.isLoading = false
                                if sender.isRefreshing{
                                    sender.endRefreshing()
                                }
                            }
                            self.tableView.performBatchUpdates({
                                self.tableView.reloadRows(at: self.tableView?.indexPathsForVisibleRows ?? [], with: .none)
                            }, completion: { complete in
                                if complete{
                                }
                            })
                        }
                        else{
                            self.header?.clearAll(actionBtnTitle: "User not found")
                            self.tableView.refreshControl = nil
                            sender.removeFromSuperview()
                            self.tableView.alwaysBounceVertical = false
                            self.header?.isUserInteractionEnabled = false
                        }
                    })
                }
            }
        }
    }
    
    func setInfo(username: String?, fullname: String?, dpID: String?, image: UIImage?, notifID: String?, bio: String?, userFollowing: [String], uid: String?, followerCount: Int?, postCount: Int?, followingCount: Int?, usersBlocking: [String]){
        
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
                self.loadedProducts.removeAll()
                self.cellHeights.removeAll()
                self.tableView.reloadData()
            }
        }
    }
    
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
        guard downloader != nil else{return}
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(friendUID).collection("Products").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).whereField("Has_Picture", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        else if let last = fromInterval{
            query = Firestore.firestore().collection("Users").document(friendUID).collection("Products").whereField("Timestamp", isLessThan: Timestamp(date: last)).whereField("Has_Picture", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true)
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
                                
                                productsToUse.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: nil, comments: comments))
                                
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
        
        if !optionMenu.isHidden{
            openOptionMenu(nil)
            return
        }
        
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
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if let last = self.loadedProducts.last{
                
                if let interval = last.timestamp{
                    
                    if !self.isLoading{
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
    
    
    
    
    
    
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let user = self.loadedProducts[indexPath.row]
        let cell = tableView.setPictureCell(indexPath: indexPath, product: user, productLocation: self)
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        tableView.syncPostLikes(loadedProducts: loadedProducts, vc: self)
        if self.downloader == nil{
            self.downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
    }


    override func viewDidDisappear(_ animated: Bool) {
        downloader?.invalidateSessionAndCancel(true)
        downloader = nil
    }
    
    override func didReceiveMemoryWarning() {
        likeQueue.removeAll()
        DispatchQueue.global(qos: .background).sync {
            cache.clearMemory()
        }
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
       
        view.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.9)

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
        optionMenuActionBtn1.backgroundColor = ColorCompatibility.tertiarySystemFill
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
        optionMenuActionBtn2.backgroundColor = ColorCompatibility.tertiarySystemFill
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
        optionMenuCancelBtn.backgroundColor = ColorCompatibility.tertiarySystemFill
        optionMenuCancelBtn.setTitleColor(ColorCompatibility.label, for: .normal)
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
                self.header?.followerNum.text = "\(self.friendInfo.followerCount! - 1)"
                guard var followingCount = userInfo.followingCount else{return}
                followingCount -= 1
                UserDefaults.standard.set(followingCount, forKey: "FOLLOWING_COUNT")
                userInfo.userFollowing.removeAll(where: {$0 == friendUID})
                UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
            }
            if isFollower{
                self.header?.followingNum.text = "\(self.friendInfo.followingCount! - 1)"
                guard var followerCount = userInfo.followerCount else{return}
                followerCount -= 1
                UserDefaults.standard.set(followerCount, forKey: "FOLLOWER_COUNT")
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
        
        Functions.functions().httpsCallable("blockOrUnblock").call(data, completion: { result, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
               
            }
        })
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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
        if let commentsVC = segue.destination as? CommentsVC{
            commentsVC.post = productToOpen
        }
        else if let reportVC = (segue.destination as? UINavigationController)?.viewControllers.first as? ReportVC{
            reportVC.reportLevel = reportType
        }
    }

}

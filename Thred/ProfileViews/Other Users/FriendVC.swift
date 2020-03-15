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
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false

        self.navigationController?.delegate = self
        self.navigationController?.navigationBar.layer.shadowColor = nil
        
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")

        self.header = self.tableView.loadUserHeaderFromNib()
        self.tableView.addSubview(refresher)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage.init()

        self.header?.clearAll(actionBtnTitle: header?.headerActionBtnTitle ?? "null")
        header?.actionBtn.addTarget(self, action: #selector(followBtnPressed(_:)), for: .touchUpInside)

        if let image = friendInfo.dp{
            self.header?.setUpInfo(username: friendInfo.username, fullname: friendInfo.fullName, bio: friendInfo.bio, notifID: friendInfo.notifID, dpUID: nil, image: image, actionBtnTitle: header?.headerActionBtnTitle ?? "null")
        }

        

     
        if friendInfo.dp == nil{
            self.refresh(refresher)
        }
        else{
            
            if let vcIndex = navigationController?.viewControllers.firstIndex(of: self){
                if navigationController?.viewControllers[vcIndex - 1] is FullProductVC || navigationController?.viewControllers[vcIndex - 1] is FeedVC{
                    self.refresh(refresher)
                }
                else{
                    self.downloadProducts(){
                        return
                    }
                }
            }
        }
    }
    
    
    @objc func followBtnPressed(_ sender: UIButton){
        
        guard let following = userInfo.userFollowing else{return}
        let didFollow = !following.contains(friendInfo.uid)
        header?.updateFollowBtn(didFollow: didFollow, animated: true)
        updateFollowInDatabase(didFollow: didFollow)
    }
    
    func updateFollowInDatabase(didFollow: Bool){
        
        if didFollow{
            let data = [
                 "UID" : friendInfo.uid
             ]
            Firestore.firestore().document("Users/\(userInfo.uid)/Following/\(friendInfo.uid)").setData(data, completion: { error in
                 if error != nil{
                     print(error?.localizedDescription ?? "")
                 }
                 else{
                    userInfo.userFollowing?.append(self.friendInfo.uid)
                    UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
                 }
             })
        }
        else{
            Firestore.firestore().collection("Users/\(userInfo.uid)/Following").document(friendInfo.uid).delete(
                completion: { error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                }
                else{
                    userInfo.userFollowing?.removeAll(where: {$0 == self.friendInfo.uid})
                    UserDefaults.standard.set(userInfo.userFollowing, forKey: "FOLLOWING")
                }
            })
        }
    }
    
    func setUpInfo(username: String?, fullname: String?, bio: String?, notifID: String?, dpUID: String?, data: Data){
    
        if let header = self.tableView.tableHeaderView as? ProfileHeaderView{
            header.usernameLbl.text = "@" + (username ?? "null")
            header.fullnameLbl.text = fullname ?? "null"
            header.bioView.text = bio
            header.actionBtn.setTitle(header.headerActionBtnTitle, for: .normal)
            let image = UIImage.init(data: data)
            header.profileImgView.image = image
        }
    }
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
        
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
                self.tableView.downloadUserInfo(uid: self.friendInfo.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: true, doNotDownloadDP: false, downloader: self.downloader, userInfo: self.friendInfo, completed: { fullName, username, dpID, notifID, bio, image, userFollowing in
                    
                    if username != nil{
                        
                        self.setInfo(username: username, fullname: fullName, dpID: dpID, image: image, notifID: notifID, bio: bio, userFollowing: userFollowing)

                        self.header?.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: self.header?.headerActionBtnTitle ?? "null")

                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: self.tableView?.indexPathsForVisibleRows ?? [], with: .none)
                        }, completion: { complete in
                            if complete{
                            }
                        })
                    }
                })
                self.downloadProducts(){[weak self] in
                    self?.isLoading = false
                    if sender.isRefreshing{
                        sender.endRefreshing()
                    }
                }
            }
        }
    }
    
    func setInfo(username: String?, fullname: String?, dpID: String?, image: UIImage?, notifID: String?, bio: String?, userFollowing: [String]?){
        
        guard let username = username else{return}
        guard let fullname = fullname else{return}
        guard let dpID = dpID else{return}
        //guard let notifID = notifID else{return}
        guard let bio = bio else{return}
        
        friendInfo.username = username
        friendInfo.fullName = fullname
        friendInfo.dpID = dpID
        friendInfo.bio = bio
        friendInfo.userFollowing = userFollowing
        //self.friendInfo.notifID = notifID
        
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
            else{
                for i in 0..<self.loadedProducts.count{
                    self.loadedProducts[i].fromCache = false
                    self.tableView.performBatchUpdates({
                        self.tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
                    }, completion: { completed in
                        if completed{
                            if i == self.loadedProducts.count - 1{}
                        }
                    })
                }
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
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(friendInfo.uid).collection("Products").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        else if let last = fromInterval{
            query = Firestore.firestore().collection("Users").document(friendInfo.uid).collection("Products").whereField("Timestamp", isLessThan: Timestamp(date: last)).limit(to: 8).order(by: "Timestamp", descending: true)
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

        let isFollowing = (userInfo.userFollowing?.contains(friendInfo.uid) ?? false)
        header?.actionBtn.setTitle("", for: .normal)
        header?.updateFollowBtn(didFollow: isFollowing, animated: false)
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
        
    }
    

}

//
//  FriendVC.swift
//  Thred
//
//  Created by Artak on 2019-11-05.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit
import FirebaseFirestore
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
        tableView.register(UINib(nibName: "ProductWithTextCell", bundle: nil), forCellReuseIdentifier: "TextProduct")

        self.header = self.tableView.loadUserHeaderFromNib()
        self.tableView.addSubview(refresher)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage.init()

        self.header?.clearAll(actionBtnTitle: "Follow")
        
        if let image = friendInfo.dp{
            self.header?.setUpInfo(username: friendInfo.username, fullname: friendInfo.fullName, bio: friendInfo.bio, notifID: friendInfo.notifID, dpUID: nil, image: image, actionBtnTitle: "Follow")
        }
     
        if friendInfo.dp == nil{
            self.refresh(refresher)
        }
        else{
            self.downloadProducts(){
                return
            }
        }
    }
    
    func setUpInfo(username: String?, fullname: String?, bio: String?, notifID: String?, dpUID: String?, data: Data){
    
        if let header = self.tableView.tableHeaderView as? ProfileHeaderView{
            header.usernameLbl.text = "@" + (username ?? "null")
            header.fullnameLbl.text = fullname ?? "null"
            header.bioView.text = bio
            header.actionBtn.setTitle("Follow", for: .normal)
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
                self.tableView.downloadUserInfo(uid: self.friendInfo.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: true, downloader: self.downloader, userInfo: self.friendInfo, completed: { fullName, username, dpID, notifID, bio, image in
                    
                    
                    if image != nil{
                        self.friendInfo.dp = nil
                        if dpID != self.friendInfo.dpID{
                            self.friendInfo.dpID.removeAll()
                        }
                    }
                    if username != nil{
                        self.friendInfo.username.removeAll()
                        self.friendInfo.fullName.removeAll()
                        self.friendInfo.bio.removeAll()
                        self.friendInfo.notifID.removeAll()
                        
                        self.header?.setUpInfo(username: username, fullname: fullName, bio: bio, notifID: notifID, dpUID: dpID, image: image, actionBtnTitle: "Follow")
                        
                        self.setInfo(username: username, fullname: fullName, dpID: dpID, image: image, notifID: notifID, bio: bio)
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
    
    func setInfo(username: String?, fullname: String?, dpID: String?, image: UIImage?, notifID: String?, bio: String?){
        
        guard let username = username else{return}
        guard let fullname = fullname else{return}
        guard let dpID = dpID else{return}
        guard let notifID = notifID else{return}
        guard let bio = bio else{return}
        
        self.friendInfo.username = username
        self.friendInfo.fullName = fullname
        self.friendInfo.dpID = dpID
        self.friendInfo.bio = bio
        self.friendInfo.notifID = notifID
        
        guard let img = image else{return}
        self.friendInfo.dp = img

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
        guard let searchDate = currentDate(asString: true, dateToUse: Date(), toFirestoreFormat: true).0 else{return}
        var query: Query! = nil
        //REMOVE LATER
        //
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users").document(friendInfo.uid).collection("Posts").whereField("Timestamp", isLessThanOrEqualTo: searchDate).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        else if let last = fromInterval{
            query = Firestore.firestore().collection("Users").document(friendInfo.uid).collection("Posts").whereField("Timestamp", isLessThan: last).limit(to: 8).order(by: "Timestamp", descending: true)
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
                    for (index, snap) in snaps.enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
                        if !self.loadedProducts.contains(where: {$0.productID == snap.documentID}){
                            let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                            let uid = snap["UID"] as! String
                            let description = snap["Description"] as? String
                            let name = snap["Name"] as? String

                            guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                            

                            self.loadedProducts.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, fromCache: false, price: priceCents / 100, name: name))
                            self.tableView.performBatchUpdates({
                                self.tableView.insertRows(at: [IndexPath(row: self.loadedProducts.count - 1, section: 0)], with: .automatic)
                            }, completion: { finished in
                                if finished{
                                    
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
        return cellHeights[indexPath] ?? 100
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        productToOpen = self.loadedProducts[indexPath.row]
        
        self.performSegue(withIdentifier: "ToProduct", sender: nil)
        
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
        let cell = tableView.setPictureCell(indexPath: indexPath, user: user, productLocation: self)
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.downloader == nil{
            self.downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
    }


    override func viewDidDisappear(_ animated: Bool) {
        downloader?.invalidateSessionAndCancel(true)
        downloader = nil
    }
    
    override func didReceiveMemoryWarning() {
        
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
        
        
    }
    

}

//
//  FeedVC.swift
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
import ColorCompatibility



public let dateUnits = ["year", "month", "week", "day", "hour", "minute", "second"]
public let userCalendar = Calendar.current


class Product: Codable, Equatable{
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        
        
        let nameCon = lhs.name == rhs.name
        let descriptionCon = lhs.description == rhs.description
        let productIDCon = lhs.productID == rhs.productID
        let priceCon = lhs.price == rhs.price
        let picIDCon = lhs.picID == rhs.picID
        let timeCon = lhs.timestamp == rhs.timestamp
        let blurCon = lhs.blurred == rhs.blurred
        let likesCon = lhs.likes == rhs.likes
        let commentCon = lhs.comments == rhs.comments
        return nameCon && descriptionCon && productIDCon && priceCon && picIDCon && timeCon && blurCon && likesCon && commentCon
        
    }
    
    var uid = String()
    var picID: String? = nil
    var description: String? = nil
    var username: String? = nil
    var fullName: String? = nil
    var productID = String()
    var userImageID: String? = nil
    var timestamp: Date! = nil
    var index: Int! = nil
    var timestampDiff: String! = nil
    var blurred: Bool!
    var price: Double? = 0
    var name: String? = nil
    var templateColor: String!
    var likes = Int()
    var liked: Bool!
    var designImage: Data!
    var comments = Int()

    
    init(uid: String, picID: String?, description: String?, fullName: String?, username: String?, productID: String, userImageID: String?, timestamp: Date!, index: Int!, timestampDiff: String!, blurred: Bool!, price: Double?, name: String?, templateColor: String!, likes: Int!, liked: Bool!, designImage: Data!, comments: Int!) {
        
        self.uid = uid
        self.picID = picID
        self.description = description
        self.username = username
        self.fullName = fullName
        self.productID = productID
        self.userImageID = userImageID
        self.timestamp = timestamp
        self.index = index
        self.timestampDiff = timestampDiff
        self.blurred = blurred
        self.price = price
        self.name = name
        self.templateColor = templateColor
        self.likes = likes
        self.liked = liked
        self.designImage = designImage
        self.comments = comments
    }
    
    convenience init() {
        self.init(uid: "", picID: nil, description: nil, fullName: nil, username: "", productID: "", userImageID: nil, timestamp: nil,  index: nil, timestampDiff: nil, blurred: false, price: nil, name: nil, templateColor: nil, likes: 0, liked: false, designImage: nil, comments: 0)
    }
    
}

class FeedVC: UITableViewController, UISearchBarDelegate {
    
    var loadedProducts = [Product]()
    var isLoading = Bool()
    let uid = UserDefaults.standard.string(forKey: "UID")
    var downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
    var tokens = [String]()
    var downloadCount = 0
    var downloadingProfiles = [String]()
    var selectedUser: UserInfo?

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadedProducts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let user = self.loadedProducts[indexPath.row]
        let cell = tableView.setPictureCell(indexPath: indexPath, product: user, productLocation: self)
        return cell
        
    }
    
    override func didReceiveMemoryWarning() {
        likeQueue.removeAll()
        DispatchQueue.global(qos: .background).sync {
            cache.clearMemory()
        }
    }
    
    @objc func newproduct(_ sender: UIBarButtonItem){
        performSegue(withIdentifier: "newproduct", sender: nil)
    }
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
                
        if !isLoading{
            isLoading = true
            sender.animateRefresh()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadProducts(){
                    self.isLoading = false
                    sender.endRefreshing()
                    self.loadedProducts.saveAllObjects(type: "FeedProducts")
                }
            }
        }
    }
    

    
    
    func clearTableView(){
        self.loadedProducts.removeAll()
        self.cellHeights.removeAll()
        self.tableView.reloadData()
    }
    
    func downloadProducts(completed: @escaping () -> ()){
        guard let uid = userInfo.uid else{completed(); return}
        refreshLists(userUID: uid){
            self.getProducts(fromInterval: nil) { hasDiffproducts, snapDocs in
                completed()
                if hasDiffproducts ?? false{
                    self.clearTableView()
                }
                else{
                    for i in 0..<(self.loadedProducts.count){
                        if self.loadedProducts[i].uid == userInfo.uid{
                            continue
                        }
                        self.loadedProducts[i].userImageID = nil
                    }
                }
            }
        }
    }
    
    @IBAction func unwindToFeed(segue:  UIStoryboardSegue) {
        
        //if let button = getProfileBtn(){
         //   button.setImage(userInfo.dp, for: .normal)
        //}
    }
    

    /*
    func addTemplates(){
        let idData = [
            ["Code": "black", "Display": "Black"],
            ["Code": "blue1", "Display": "Light Blue"],
            ["Code": "blue2", "Display": "Royal Blue (Heather)"],
            ["Code": "blue3", "Display": "Royal Blue"],
            ["Code": "cyan", "Display": "Sapphire Blue"],
            ["Code": "gray1", "Display": "Silver"],
            ["Code": "gray2", "Display": "Athletic Gray (Heather)"],
            ["Code": "gray3", "Display": "Medium Gray"],
            ["Code": "gray4", "Display": "Charcoal Gray"],
            ["Code": "gray5", "Display": "Dark Gray (Heather)"],
            ["Code": "green1", "Display": "Lime Green"],
            ["Code": "green2", "Display": "Kelly Green"],
            ["Code": "green3", "Display": "Dark Green"],
            ["Code": "navy1", "Display": "Navy Blue (Heather)"],
            ["Code": "navy2", "Display": "Navy Blue"],
            ["Code": "navy3", "Display": "Dark Navy Blue"],
            ["Code": "orange", "Display": "Orange"],
            ["Code": "pink", "Display": "Sangria Pink"],
            ["Code": "purple", "Display": "Purple"],
            ["Code": "red1", "Display": "Red (Heather)"],
            ["Code": "red2", "Display": "Red"],
            ["Code": "red3", "Display": "Maroon"],
            ["Code": "white", "Display": "White"],
            ["Code": "yellow1", "Display": "Yellow"],
            ["Code": "yellow2", "Display": "Gold"],
        ]
        let data = [
            "IDs" : idData,
        ]
        Firestore.firestore().collection("Templates").document("Tees").setData(data)
    }
*/
 
    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.allowsSelection = false
        //cache.config.maxMemoryCost = 15 * 1024 * 1024
        
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        tableView.register(UINib(nibName: "ProductWithTextCell", bundle: nil), forCellReuseIdentifier: "TextProduct")
        //FeedVC.searchTable.register(EmptyFeedVC.searchTableViewCell.self, forCellReuseIdentifier: "emptySearch")
        navigationController?.navigationBar.layer.shadowColor = nil
        
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        
        //userInfo.dp = userInfo.defaultDP
        //userInfo.username = "artathecanadiann"
        //userInfo.fullName = "arta"
        
        //let l = customView.constraints.first(where: {$0.})
              
              //refresher.attributedTitle = NSAttributedString(string: "Pull to Refresh 👽")
              
        //self.tableView.refreshControl = refresher
        tableView.addSubview(refresher)

        //let image = userInfo.dp
        
        //setupUI(image: image!)
        //navigationItem.titleView = FeedVC.searchBar
        
        
        //UserDefaults.standard.set("vK39Da3RIGVGsgBgpdkj0CWdtdW2", forKey: "UID") //Arta
        //UserDefaults.standard.set("tl1oOs1NXdeHsium7ZygweBc7YO2", forKey: "UID") //Arvin
        //UserDefaults.standard.set("te7lsnwiPUMyj85O4Q5Tkvuu3VH3", forKey: "UID") //Dad
        
        
        
        
        
        //contentInset.left = 0
        //self.tableView.contentInset.right = 0

        //backgroundView.startAnimating()
        

        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage.init()
        //
        //userInfo.dp = UIImage.init(named: "night")
        
        
        //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - (refresher.frame.size.height)), animated: true)
        
        refresher.beginRefreshing()
        
        
        loadedProducts.checkAndLoadProducts(vc: self, type: "FeedProducts") { count in
            DispatchQueue.main.async{
                switch count{
                case 0:
                    self.refresh(refresher)
                default:
                    DispatchQueue.main.async {
                        if count == self.loadedProducts.count{
                            self.refresh(refresher)
                        }
                    }
                }
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if let last = loadedProducts.last{
                if let interval = last.timestamp{
                    if !isLoading{
                        isLoading = true
                        getProducts(fromInterval: interval){_,_ in
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
    
    var query: Query! = nil
    
    func loadProducts(){
        
        
    }

    func getProducts(fromInterval: Date?, completed: @escaping (Bool?, [DocumentSnapshot]?) -> ()){
        

        guard let userUID = userInfo.uid else{
            completed(false, nil)
        return}

        //REMOVE LATER
        if !userInfo.userFollowing.contains(userUID){
            userInfo.userFollowing.append(userUID)
        }
        query = nil
        if fromInterval == nil{
            query = Firestore.firestore().collectionGroup("Products").whereField("UID", in: userInfo.userFollowing ).whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).whereField("Has_Picture", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        if let last = fromInterval{
            query = Firestore.firestore().collectionGroup("Products").whereField("UID", in: userInfo.userFollowing).whereField("Timestamp", isLessThan: Timestamp(date: last)).whereField("Has_Picture", isEqualTo: true).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        
        self.query.getDocuments(completion: { (snapDocuments, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completed(false, nil)
                return
            }
            else{
                if snapDocuments?.isEmpty ?? true{
                    completed(false, nil)
                }
                else{
                    guard let snaps = snapDocuments?.documents else {
                        return}
                    if snapDocuments?.metadata.isFromCache ?? false{
                        completed(false, snaps)
                    }
                    else{
                        
                        var localLoaded: [Product]! = [Product]()
                        for (index, snap) in snaps.enumerated(){
                            let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                            let uid = snap["UID"] as! String
                            if userInfo.usersBlocking.contains(uid){
                                continue
                            }
                            let description = snap["Description"] as? String
                            let name = snap["Name"] as? String
                            let blurred = snap["Blurred"] as? Bool
                            let templateColor = snap["Template_Color"] as? String
                            let likes = snap["Likes"] as? Int
                            guard let priceCents = (snap["Price_Cents"] as? Double) else{continue}
                            let comments = ((snap["Comments"]) as? Int) ?? 0
                            localLoaded.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments))
                        
                        }
                        switch fromInterval{
                        case .none:
                            let isSame = localLoaded == self.loadedProducts
                            if !isSame{
                                self.loadedProducts.removeOldFeedPosts(newPosts: localLoaded)
                                completed(true, snaps)
                                self.sortDownloadedProducts(products: localLoaded){
                                    localLoaded = nil
                                    self.loadedProducts.saveAllObjects(type: "FeedProducts")
                                }
                            }
                            else{
                                localLoaded = nil
                                completed(false, snaps)
                            }
                        default:
                            self.sortDownloadedProducts(products: localLoaded){
                                localLoaded = nil
                                completed(true, snaps)
                            }
                        }
                    }
                }
            }
        })
    }
    
    func sortDownloadedProducts(products: [Product], completed: @escaping () -> ()){
        
        var productsToUse: [Product]! = [Product]()
        for product in products{ // LOADED DOCUMENTS FROM \(snapDocuments)
        
            if !loadedProducts.contains(where: {$0.productID == product.productID}){
                
                guard let userUID = userInfo.uid else{return}
                Firestore.firestore().collection("Users").document(product.uid).collection("Products").document(product.productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                
                    
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
   
    var cellHeights: [IndexPath: CGFloat] = [:]
    
    ///* Dynamic Cell Sizing *///
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ///For every cell, retrieve the height value and store it in the dictionary
        if tableView == self.tableView{
            cellHeights[indexPath] = cell.frame.size.height
        }
    }
    

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 1500
    }
    
    
    
    
    var productToOpen: Product!

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.showCenterBtn()
        
        tableView.syncPostLikes(loadedProducts: loadedProducts, vc: self)
        loadedProducts.saveAllObjects(type: "FeedProducts")
        
        for post in loadedProducts.filter({$0.uid == userInfo.uid && $0.userImageID != userInfo.dpID}){
            
            if let index = loadedProducts.firstIndex(where: {$0.productID == post.productID}){
                loadedProducts[index].userImageID = userInfo.dpID
                tableView.performBatchUpdates({
                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }, completion: nil)
            }
        }
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
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
        if let commentsVC = segue.destination as? CommentsVC{
            commentsVC.post = productToOpen
        }
        else if let friend = segue.destination as? FriendVC{
            friend.friendInfo = selectedUser!
        }
        else if let designVC = (segue.destination as? UINavigationController)?.viewControllers.first as? DesignViewController{
            if let img = cache.imageFromCache(forKey: productToOpen.productID){
                designVC.product = ProductInProgress(templateColor: productToOpen.templateColor, design: img, uid: productToOpen.uid, caption: productToOpen.description, name: productToOpen.name, price: productToOpen.price, productID: productToOpen.productID)
            }
        }
        else if let reportVC = (segue.destination as? UINavigationController)?.viewControllers.first as? ReportVC{
            reportVC.reportLevel = .post
        }
    }
}



extension UITableView{
    
    func loadUserHeaderFromNib() -> ProfileHeaderView?{
        let profileHeaderView = UINib(
            nibName: "ProfileHeaderView",
            bundle: nil
        ).instantiate(withOwner: nil, options: nil)[0] as? ProfileHeaderView
        tableHeaderView = profileHeaderView
        return profileHeaderView
    }
}


extension UIViewController{
    
    func refreshLists(userUID: String, completed: @escaping () -> ()){
        Firestore.firestore().collection("Users").document(userUID).getDocument(completion: { doc, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                userInfo.usersBlocking = (doc?["Users_Blocking"] as? [String]) ?? []
                userInfo.userFollowing = (doc?["Following_List"] as? [String]) ?? []
            }
            completed()
        })
    }
}

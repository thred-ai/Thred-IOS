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
import Firebase
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

    
    init(uid: String, picID: String?, description: String?, fullName: String?, username: String?, productID: String, userImageID: String?, timestamp: Date?, index: Int?, timestampDiff: String?, blurred: Bool?, price: Double?, name: String?, templateColor: String?, likes: Int?, liked: Bool?, designImage: Data?, comments: Int?) {
        
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
        self.likes = likes ?? 0
        self.liked = liked
        self.designImage = designImage
        self.comments = comments ?? 0
    }
    
    convenience init() {
        self.init(uid: "", picID: nil, description: nil, fullName: nil, username: "", productID: "", userImageID: nil, timestamp: nil,  index: nil, timestampDiff: nil, blurred: false, price: nil, name: nil, templateColor: nil, likes: 0, liked: false, designImage: nil, comments: 0)
    }
    
}

class FeedVC: UITableViewController, UISearchBarDelegate {
    
    var loadedProducts = [Product]()
    var isLoading = true
    let uid = UserDefaults.standard.string(forKey: "UID")
    var tokens = [String]()
    var downloadCount = 0
    var downloadingProfiles = [String]()
    var selectedUser: UserInfo?

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return loadedProducts.count
    }
    
    @IBAction func toCart(_ sender: UIBarButtonItem) {
           navigationController?.segueToCart()
       }
       
       @IBAction func toSales(_ sender: UIBarButtonItem) {
           navigationController?.segueToSales()
           
           
    
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
            lastIndex = 0
            isLoading = true
            sender.animateRefresh()
            self.downloadProducts(){
                self.isLoading = false
                sender.endRefreshing()
                self.loadedProducts.saveAllObjects(type: "FeedProducts")
            }
        }
    }
    

    
    
    func clearTableView(){
        self.loadedProducts.removeAll()
        self.cellHeights.removeAll()
        self.tableView.reloadData()
    }
    
    lazy var headerView: UIView? = {
        
        return loadFeedPostHeaderFromNib()
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
            return 175
        }
        return 0
    }
    
    func downloadProducts(completed: @escaping () -> ()){
        guard let uid = userInfo.uid else{completed(); return}
        checkAuthStatus {
            self.refreshLists(userUID: uid){
                self.getProducts(refresh: true) { hasDiffproducts in
                    if hasDiffproducts ?? false{
                        if !self.loadedProducts.isEmpty{
                            self.clearTableView()
                        }
                        DispatchQueue.main.async {
                            completed()
                        }
                    }
                    else{
                        
                        for i in 0..<(self.loadedProducts.count){
                            if self.loadedProducts[i].uid == userInfo.uid{
                                continue
                            }
                            self.loadedProducts[i].userImageID = nil
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            completed()
                        }
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
    
    var selectedReportID: String!
    var selectedReportUID: String!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.allowsSelection = false
        //cache.config.maxMemoryCost = 15 * 1024 * 1024
        
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        tableView.register(UINib(nibName: "ProductWithTextCell", bundle: nil), forCellReuseIdentifier: "TextProduct")
        navigationController?.navigationBar.layer.shadowColor = nil
        
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        
        tableView.addSubview(refresher)

        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage.init()

        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - (refresher.frame.size.height)), animated: true)
        
        refresher.beginRefreshing()
        
        
        loadedProducts.checkAndLoadProducts(vc: self, type: "FeedProducts") { count in
            DispatchQueue.main.async{
                self.isLoading = false
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
            
            if !UserDefaults.standard.bool(forKey: "showedAuthMsg"){
                UserDefaults.standard.set(true, forKey: "showedAuthMsg")

            }

            if !UserDefaults.standard.bool(forKey: "showedCovidMsg"){
                UserDefaults.standard.set(true, forKey: "showedCovidMsg")
                self.showErrorMessage {
                    
                }
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if !isLoading{
                isLoading = true
                getProducts(refresh: false){_ in
                    self.isLoading = false
                    if self.refreshControl?.isRefreshing ?? true{
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
    
    var query: Query! = nil
    var lastIndex = 0

    func getProducts(refresh: Bool, time completed: @escaping (Bool?) -> ()){

        guard let userUID = userInfo.uid else{
            completed(false)
        return}

        //REMOVE LATER
        
        var clone = userInfo.userFollowing
        if !clone.contains(userUID){
            clone.append(userUID)
        }
        
        query = nil
        
        let arrays = clone.chunked(into: 10)
        var localLoaded: [Product]! = [Product]()
        var totalDocs = [DocumentSnapshot]()
        let docLimit = 8
        
        if arrays.indices.contains(lastIndex){
            let array = arrays[lastIndex]
            lastIndex = (arrays.firstIndex(of: array) ?? 0) + 1
            query = Firestore.firestore().collectionGroup("Products").whereField("UID", in: array).whereField("Has_Picture", isEqualTo: true).limit(to: docLimit).order(by: "Timestamp", descending: true)
            query.getDocuments(completion: { (snapDocuments, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                }
                else{
                    if snapDocuments?.isEmpty ?? true{
                        self.isLoading = false
                        self.refresh(self.tableView.refreshControl as! BouncingTitleRefreshControl)
                    }
                    else{
                        guard let snaps = snapDocuments?.documents else {
                            self.isLoading = false
                            self.refresh(self.tableView.refreshControl as! BouncingTitleRefreshControl)
                            return}
                        if snapDocuments?.metadata.isFromCache ?? false{
                            
                        }
                        else{
                            for (index, snap) in snaps.enumerated(){
                                totalDocs.append(snap)
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
                                let product = Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments)
                                localLoaded.append(product)
                            }
                        }
                    }
                }
                self.checkSameProducts(localLoaded: localLoaded, completed: { isNew in
                    if isNew{
                        completed(true)
                    }
                    else{
                        completed(false)
                    }
                })
            })
        }
        else{
            completed(false)
        }
    }
    
    func checkLoaded(localLoaded: [Product]?){
        
    }
    
    func checkSameProducts(localLoaded: [Product], completed: @escaping (Bool) -> ()){
        let isSame = localLoaded == self.loadedProducts
        if !isSame{
            self.loadedProducts.removeOldFeedPosts(newPosts: localLoaded)
            completed(true)
            self.sortDownloadedProducts(products: localLoaded){
                //localLoaded = nil
                self.loadedProducts.saveAllObjects(type: "FeedProducts")
            }
        }
        else{
            //localLoaded = nil
            completed(false)
        }
    }
    
    /*
     
     
     
     */
    
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
            reportVC.reportUID = selectedReportUID
            reportVC.reportPostID = selectedReportID
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
    
    func loadFeaturedHeaderFromNib() -> FeaturedPostView?{
        let featuredPostView = UINib(
            nibName: "FeaturedPostView",
            bundle: nil
        ).instantiate(withOwner: nil, options: nil)[0] as? FeaturedPostView
        tableHeaderView = featuredPostView
        return featuredPostView
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
    func loadFeedPostHeaderFromNib() -> EmptyProductsView?{
        let productsHeaderView = UINib(
            nibName: "EmptyProductsView",
            bundle: nil
        ).instantiate(withOwner: nil, options: nil)[0] as? EmptyProductsView
        return productsHeaderView
    }
    
    func loadProfilePostHeaderFromNib() -> EmptyProfileProductsView?{
        let productsHeaderView = UINib(
            nibName: "EmptyProfileProductsView",
            bundle: nil
        ).instantiate(withOwner: nil, options: nil)[0] as? EmptyProfileProductsView
        
        return productsHeaderView!
    }
    
    func loadLoadingHeaderFromNib() -> LoadingView?{
        let loadingView = UINib(
            nibName: "LoadingView",
            bundle: nil
        ).instantiate(withOwner: nil, options: nil)[0] as? LoadingView
        return loadingView!
    }
    
    func loadNotifHeaderFromNib() -> EmptyNotifView?{
        let notifHeaderView = UINib(
            nibName: "EmptyNotifView",
            bundle: nil
        ).instantiate(withOwner: nil, options: nil)[0] as? EmptyNotifView
        return notifHeaderView
    }
    
    func loadCartHeaderFromNib() -> EmptyCartView?{
        let cartHeaderView = UINib(
            nibName: "EmptyCartView",
            bundle: nil
        ).instantiate(withOwner: nil, options: nil)[0] as? EmptyCartView
        return cartHeaderView
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

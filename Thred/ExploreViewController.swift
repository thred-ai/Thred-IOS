//
//  ExploreViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-01-16.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import Stripe
import SDWebImage
import ColorCompatibility

var factor: CGFloat{
    let factor = CGFloat(220.0 / 729.0)
    print(factor)
    return factor
}

class ExploreViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{

    var colorSections = [[String : Any?]]()
    @IBOutlet var tableView: UITableView!
    
    
    var productToOpen: Product!
    var featuredHeader: FeaturedPostView!
    var featuredProduct: Product!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(UINib(nibName: "ExploreColorCell", bundle: nil), forCellReuseIdentifier: "ExploreColorCell")
        featuredHeader = tableView.loadFeaturedHeaderFromNib()
        featuredHeader.vc = self
        searchBar.delegate = self
        
        navigationItem.titleView = searchBar
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
       
        tableView.addSubview(refresher)
        
        tableView.adjustForCenterBtn(footerColor: nil, offset: 5, vc: self)
        
        
        getTemplates{_ in
            self.isLoading = false
        }
    }
    
    
    
    func getFeaturedPost(){
        
        guard let userUID = userInfo.uid else{return}
        Firestore.firestore().collectionGroup("Products").whereField("Public", isEqualTo: true).whereField("Timestamp", isGreaterThan: Timestamp(date: Date().adding(hours: -120))).order(by: "Timestamp").whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Likes", descending: true).limit(to: 5).getDocuments(completion: { docs, error in
            
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                guard let snaps = docs?.documents, !snaps.isEmpty else{return}
                
                for snap in snaps{
                    let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                    let uid = snap["UID"] as! String
                    let description = snap["Description"] as? String
                    let name = snap["Name"] as? String
                    let blurred = snap["Blurred"] as? Bool
                    let templateColor = snap["Template_Color"] as? String
                    let likes = snap["Likes"] as? Int
                    guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                    let comments = ((snap["Comments"]) as? Int) ?? 0

                    Firestore.firestore().collection("Users").document(uid).collection("Products").document(snap.documentID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                    
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
                        
                        let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: nil, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true)
                        
                        self.featuredHeader.featuredProducts.append(product)
                        
                        if self.featuredHeader.featuredProducts.count == 5{
                            self.featuredHeader.numberOfItems = 5
                            self.featuredHeader.featuredProducts.sort(by: {$0.likes > $1.likes})
                            DispatchQueue.main.async {
                                self.featuredHeader.collectionView.reloadData()
                            }
                        }
                    })
                }
            }
        })
    }
    
    
    lazy var searchBar: UISearchBar = {
        
        let search = UISearchBar()
        search.autocapitalizationType = .none
        search.returnKeyType = .search
        search.searchBarStyle = .default
        search.keyboardType = .alphabet
        search.tintColor = UIColor(named: "LoadingColor")
        search.placeholder = "Search users and threds"
        search.showsCancelButton = false
        
        search.searchTextField.font = UIFont(name: "NexaW01-Heavy", size: 14)
        search.searchTextField.adjustsFontSizeToFitWidth = true
        search.isTranslucent = false
        search.searchTextField.minimumFontSize = 12
        if #available(iOS 13.0, *) {
            let attributes:[NSAttributedString.Key:Any] = [
                NSAttributedString.Key.foregroundColor : UIColor.label,
                NSAttributedString.Key.backgroundColor : UIColor.clear,
                NSAttributedString.Key.font : UIFont(name: "NexaW01-Heavy", size: 16)!
            ]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            
        } else {
            let attributes:[NSAttributedString.Key:Any] = [
                NSAttributedString.Key.foregroundColor : UIColor.black,
                NSAttributedString.Key.backgroundColor : UIColor.clear,
                NSAttributedString.Key.font : UIFont(name: "NexaW01-Heavy", size: 16)!
            ]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            // Fallback on earlier versions
        }
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor(named: "ProfileMask")
        
        return search
    }()
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        self.searchedUsers.removeAll()
        searchUsersTable.reloadData()
        searchProductsTable.reloadData()
        searchBar.text?.removeAll()
        UIView.animate(withDuration: 0.1, animations: {
            self.searchView.alpha = 0.0
        }, completion: {(finished : Bool) in
            self.searchView.isHidden = true
            self.tableView.isScrollEnabled = true
        })
    }
    
    
    
    
    
    override func viewDidLayoutSubviews() {
        if !view.subviews.contains(searchView){
            view.addSubview(searchView)
            view.bringSubviewToFront(searchView)
            searchView.isHidden = true
        }
        featuredHeader.frame.size.height = view.frame.width
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        

        showCenterBtn()
        selectedUser = nil
        if let indexPath = searchUsersTable?.indexPathForSelectedRow{
            searchUsersTable?.deselectRow(at: indexPath, animated: true)
            searchUsersTable.performBatchUpdates({
                searchUsersTable.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        if let indexPath = searchProductsTable?.indexPathForSelectedRow{
            searchProductsTable?.deselectRow(at: indexPath, animated: true)
            searchProductsTable.performBatchUpdates({
                searchProductsTable.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        if let indexPath = tableView.indexPathForSelectedRow{
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.performBatchUpdates({
                tableView.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        if let indexPath = featuredHeader.collectionView?.indexPathsForSelectedItems?.first{
            featuredHeader.collectionView?.deselectItem(at: indexPath, animated: true)
            featuredHeader.collectionView?.performBatchUpdates({
                featuredHeader.collectionView?.reloadItems(at: [indexPath])
            }, completion: nil)
        }
        
        
        if searchedUsers.contains(where: {$0.username?.isEmpty ?? true || $0.fullName?.isEmpty ?? true || $0.dp == nil}){
            searchedUsers.removeAll()
            searchBar.text?.removeAll()
            DispatchQueue.main.async {
                self.searchUsersTable.reloadData()
            }
        }
        
        
        guard productToOpen != nil else{return}
        for section in colorSections{
            tableView.syncPostLikes(loadedProducts: section["Array"] as? [Product] ?? [], vc: self)
        }
        guard let colorSection = colorSections.first(where: {$0["ID"] as? String == productToOpen.templateColor}) else{return}
        guard let postArray = colorSection["Array"] as? [Product] else{return}
        guard let post = postArray.first(where: {$0.productID == productToOpen.productID}) else{return}
        post.liked = productToOpen.liked
        post.likes = productToOpen.likes
        post.userInfo.username = productToOpen.userInfo.username
        post.userInfo.fullName = productToOpen.userInfo.fullName
    }
    
    var isLoading = false
    
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
            DispatchQueue(label: "background").async {
                cache.clearMemory()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.featuredHeader.featuredProducts.removeAll()
                    self.getTemplates{ error in
                        if error == nil{
                            self.colorSections.removeAll()
                        }
                        self.isLoading = false
                        sender.endRefreshing()
                    }
                }
            }
        }
        else{
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == searchUsersTable || scrollView == searchProductsTable{
            if searchUsersTable.numberOfRows(inSection: 0) != 0{
                searchBar.resignFirstResponder()
            }
            if searchProductsTable.numberOfRows(inSection: 0) != 0{
                searchBar.resignFirstResponder()
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView{
            return colorSections.count
        }
        else if tableView == self.searchUsersTable{
            return searchedUsers.count
        }
        else if tableView == self.searchProductsTable{
            return searchedProducts.count
        }
        return 0
    }
    
    func getTemplates(completed: @escaping (Error?) -> ()){
        
        guard let uid = userInfo.uid else{return}
        checkAuthStatus {
            self.refreshLists(userUID: uid){
                self.getFeaturedPost()
                Firestore.firestore().document("Templates/Tees").getDocument(completion: { snap, error in
                    if error != nil{
                        completed(error)
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        guard let doc = snap else{return}
                        completed(nil)
                        let ids = doc["IDs"] as? [[String : String]]
                        for id in ids ?? []{
                            guard let code = id["Code"] else{continue}
                            guard let displayName = id["Display"] else{continue}

                            self.colorSections.append([
                                "Array": nil,
                                "ID": code,
                                "Display" : displayName,
                                "Offset": 0,
                                "Downloading" : [],
                                "Color_Downloading" : []
                            ])
                        }
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let cell = cell as? ExploreColorCell{
            cell.collectionViewOffset = colorSections[indexPath.row]["Offset"] as? CGFloat ?? 0
           
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ExploreColorCell{
            cell.postArray.removeAll()
            cell.collectionView.reloadData()
            if colorSections.indices.contains(indexPath.row){
                colorSections[indexPath.row]["Offset"] = cell.collectionViewOffset
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView{
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreColorCell", for: indexPath) as? ExploreColorCell
            
            let postSection = colorSections[indexPath.row]
            guard let sectionID = postSection["ID"] as? String else{return cell!}
            let displayName = postSection["Display"] as? String
            cell?.colorIcon.backgroundColor = nil
            cell?.exploreVC = nil
            cell?.templateColor = nil
            cell?.colorNameLbl.text = nil
            cell?.postArray = nil

            
            cell?.colorIcon.backgroundColor = UIColor(named: postSection["ID"] as? String ?? "null")
            cell?.colorNameLbl.text = displayName ?? "null"
            cell?.exploreVC = self
            cell?.templateColor = sectionID //problem

            if let postArray = postSection["Array"] as? [Product]{
                cell?.postArray = postArray
            }
            
            var downloading = postSection["Color_Downloading"] as? [String]
            if !(downloading?.contains(sectionID) ?? false){
                downloading?.append(sectionID)
            }
            cell?.getProducts{
                cell?.collectionView.reloadData()
            }
            return cell!
        }
        else if tableView == self.searchUsersTable{
            let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as? SearchUserTableViewCell
            let user = self.searchedUsers[indexPath.row]
            cell?.userImageView.image = nil

            if let dp = user.dp{
                cell?.spinner.isHidden = true
                cell?.userImageView.image = UIImage(data: dp)
            }
            else{
                cell?.spinner.isHidden = false
                cell?.spinner.animate()
            }
            cell?.usernameLbl.text = "@" + (user.username ?? "null")
            cell?.fullnameLbl.text = user.fullName
            return cell!
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchProductCell", for: indexPath) as? SearchProductTableViewCell
            let product = self.searchedProducts[indexPath.row]
            cell?.productImageView.image = nil
            cell?.priceLbl.text = nil
            cell?.likesLbl.text = nil
            cell?.productNameLbl.text = nil
            cell?.productImageView.backgroundColor = .secondarySystemBackground
            cell?.quantityView.isHidden = true
            cell?.sizingLbl.isHidden = true
            cell?.likesView.isHidden = false

            
            DispatchQueue(label: "explore").async {
                if let dp = cache.imageFromMemoryCache(forKey: "thumbnail_\(product.productID)"){
                    DispatchQueue.main.async {
                        cell?.productImageView.image = dp
                    }
                }
            }
            cell?.productImageView.backgroundColor = UIColor(named: product.templateColor)
            cell?.productNameLbl.text = product.name
            
            cell?.priceLbl.text = product.price?.formatPrice()

            cell?.likesLbl.text = "\(product.likes)"
                        
            return cell!
        }
    }
    
    
   
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

    }

    
    var topTab: UISegmentedControl!
    var searchUsersTable: UITableView!
    var searchProductsTable: UITableView!
           
    lazy var searchView: UIView = {
        
        let insets = self.view.safeAreaInsets
        let view = UIView.init(frame: CGRect(x: 0, y: insets.top, width: self.view.frame.width, height: self.view.frame.height - (insets.top + insets.bottom)))
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(1)

        topTab = UISegmentedControl.init(frame: CGRect(x: 5, y: 5, width: view.frame.width - 10, height: 30))
        topTab.setTitleFont(UIFont(name: "NexaW01-Heavy", size: 14)!)
        topTab.setTitleColor(.white)
        topTab.selectedSegmentTintColor = UIColor(named: "LoadingColor")
        topTab.backgroundColor = .systemGroupedBackground
        topTab.insertSegment(withTitle: "Users", at: 0, animated: false)
        
        topTab.insertSegment(withTitle: "Threds", at: 1, animated: false)
        topTab.layer.cornerRadius = 0
        topTab.selectedSegmentIndex = 0
        topTab.clipsToBounds = true
        topTab.addTarget(self, action: #selector(switchedSegment(_:)), for: .valueChanged)
        
        searchUsersTable = UITableView(frame: CGRect(x: 0, y: topTab.frame.maxY + 5, width: view.frame.width, height: view.frame.height - topTab.frame.maxY - 5))
        searchUsersTable.separatorStyle = .none
        searchUsersTable.register(UINib(nibName: "SearchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "search")
        searchUsersTable.delegate = self
        searchUsersTable.dataSource = self
        searchUsersTable.backgroundColor = .clear

        searchProductsTable = UITableView(frame: CGRect(x: 0, y: topTab.frame.maxY + 5, width: view.frame.width, height: view.frame.height - topTab.frame.maxY - 5))
        searchProductsTable.separatorStyle = .none
        searchProductsTable.register(UINib(nibName: "SearchProductTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchProductCell")
        searchProductsTable.delegate = self
        searchProductsTable.dataSource = self
        searchProductsTable.backgroundColor = .clear

        
        view.addSubview(topTab)
        view.addSubview(searchUsersTable)
        view.addSubview(searchProductsTable)
        searchProductsTable.isHidden = true

        return view
    }()
    
    @objc func switchedSegment(_ sender: UISegmentedControl){
        
        if sender.selectedSegmentIndex == 0{
            searchProductsTable.isHidden = true
            searchUsersTable.isHidden = false
            searchedUsers.removeAll()
            searchUsersTable.reloadData()
            
            if let text = searchBar.text, !text.isEmpty{
                searchUsers(searchText: text)
            }
        }
        else{
            searchUsersTable.isHidden = true
            searchProductsTable.isHidden = false
            searchedProducts.removeAll()
            searchProductsTable.reloadData()
            
            if let text = searchBar.text, !text.isEmpty{
                searchProducts(searchText: text)
            }
        }
    }
    
    
    
    


    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchView.isHidden = false
        searchBar.setShowsCancelButton(true, animated: true)
        tableView.isScrollEnabled = false
        UIView.animate(withDuration: 0.1, animations: {
            self.searchView.alpha = 1.0
        }, completion: {(finished : Bool) in
            if finished{
            }
        })
    }
    
    
    
    
    var searchedUsers = [UserInfo]()
    var searchedProducts = [Product]()

    var selectedUser: UserInfo? = UserInfo()
    
    
    
    func searchUsers(searchText: String){
        if searchText == ""{
            searchedUsers.removeAll()
            searchUsersTable.reloadData()
            //self.getFollowers()
        }
        else{
            //searchBar.isLoading = true
            Firestore.firestore().collection("Users").whereField("Username", isGreaterThanOrEqualTo: searchText).whereField("Username", isLessThanOrEqualTo: searchText + "\u{f8ff}").limit(to: 8).getDocuments(completion: { query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    self.searchedUsers.removeAll()
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{
                                let uid = document.documentID
                                let username = document["Username"] as? String
                                let fullname = document["Full_Name"] as? String
                                let bio = document["Bio"] as? String
                                let dpLink = document["ProfilePicID"] as? String
                                let userFollowing = document["Following_List"] as? [String]
                                let followerCount = document["Followers_Count"] as? Int
                                let followingCount = document["Following_Count"] as? Int
                                let postCount = document["Posts_Count"] as? Int
                                let usersBlocking = document["Users_Blocking"] as? [String]

                                if userInfo.usersBlocking.contains(uid){
                                    continue
                                }
                                
                                let user = UserInfo(uid: uid, dp: nil, dpID: dpLink, username: username, fullName: fullname, bio: bio, notifID: nil, userFollowing: userFollowing ?? [], userLiked: [], followerCount: followerCount ?? 0, postCount: postCount ?? 0, followingCount: followingCount ?? 0, usersBlocking: usersBlocking ?? [], profileLink: nil)

                                if uid == userInfo.uid{
                                    user.dp = userInfo.dp
                                    user.dpID = userInfo.dpID
                                    self.searchedUsers.append(user)
                                    self.searchUsersTable.reloadData()
                                    continue
                                }
                                
                                self.searchedUsers.append(user)
                                self.searchUsersTable.reloadData()
                                let ref = Storage.storage().reference()
                                ref.child("Users/" + uid + "/" + "profile_pic-" + (dpLink ?? "null") +
                                    ".jpeg").downloadURL(completion: { url, error in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        downloader.requestImage(with: url, options: [.scaleDownLargeImages, .refreshCached], context: nil, progress: nil, completed: { (image, data, error, finished) in
                                            if error != nil{
                                                print(error?.localizedDescription ?? "")
                                                return
                                            }
                                            else{
                                                user.dp = data
                                                if let index = self.searchedUsers.firstIndex(where: {$0.uid == uid}){
                                                    self.searchUsersTable.performBatchUpdates({
                                                        self.searchUsersTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                                    }, completion: nil)
                                                }
                                            }
                                        })
                                    }
                                })
                            }
                        }
                        else{
                            self.searchUsersTable.reloadData() //No Results
                        }
                    }
                }
            })
        }
    }
    
    
    func searchProducts(searchText: String){
        guard let userUID = userInfo.uid else{return}
        if searchText == ""{
            searchedProducts.removeAll()
            searchProductsTable.reloadData()
            //self.getFollowers()
        }
        else{
            //searchBar.isLoading = true
            Firestore.firestore().collectionGroup("Products")
                .whereField("Search_Name", isGreaterThanOrEqualTo: searchText).whereField("Search_Name", isLessThanOrEqualTo: searchText + "\u{f8ff}").whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 8).getDocuments(completion: { query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    
                    let oldProducts: [Product]! = self.searchedProducts.map({$0})
                    self.searchedProducts.removeAll()
                    
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{
                                let timestamp = (document["Timestamp"] as? Timestamp)?.dateValue()
                                if let same = oldProducts.first(where: {$0.productID == document.documentID}){
                                    self.searchedProducts.append(same)
                                    self.searchProductsTable.reloadData()
                                    continue
                                }
                                guard let uid = document["UID"] as? String else{
                                    continue}
                                let description = document["Description"] as? String
                                let name = document["Name"] as? String
                                let blurred = document["Blurred"] as? Bool
                                let templateColor = document["Template_Color"] as? String
                                let likes = document["Likes"] as? Int
                                guard let priceCents = (document["Price_Cents"] as? Double) else{continue}
                                let comments = ((document["Comments"]) as? Int) ?? 0
                                let productID = document.documentID
                                
                                let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil), picID: productID, description: description, productID: productID, timestamp: timestamp, index: 0, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(productID), designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true)

                                Firestore.firestore().collection("Users").document(uid).collection("Products").document(productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                                
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        userInfo.userLiked.removeAll(where: {$0 == productID})
                                        if let likeDocs = snapLikes?.documents{
                                            if likeDocs.isEmpty{
                                                product.liked = false
                                            }
                                            else{
                                                product.liked = true
                                                if !(userInfo.userLiked.contains(productID)){
                                                    userInfo.userLiked.append(productID)
                                                }
                                            }
                                        }
                                        else{
                                            product.liked = false
                                        }
                                    }
                                    self.searchedProducts.append(product)
                                    self.searchedProducts.sort(by: {$0.likes > $1.likes})
                                    self.searchProductsTable.reloadData()
                                    
                                    let ref = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + productID + "/" + "thumbnail_\(productID)" + ".png")
                                    ref.downloadURL(completion: { url, error in
                                        if error != nil{
                                            print(error?.localizedDescription ?? "")
                                        }
                                        else{
                                            var dub: CGFloat = 0
                                            downloader.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                                                dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                                                print("Progress \(dub)")
                                            }, completed: { (image, data, error, finished) in
                                                if error != nil{
                                                    print(error?.localizedDescription ?? "")
                                                }
                                                else{
                                                    if let image = image{
                                                        cache.storeImage(toMemory: image, forKey: "thumbnail_\(productID)")
                                                        if let index = self.searchedProducts.firstIndex(where: {$0.productID == document.documentID}){
                                                            self.searchProductsTable.performBatchUpdates({
                                                                self.searchProductsTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                                            }, completion: nil)
                                                        }
                                                    }
                                                }
                                            })
                                        }
                                    })
                                })
                            }
                        }
                        else{
                            self.searchProductsTable.reloadData()
                        }
                    }
                }
            })
        }
    }
    
    
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let lowerCaseSearchText = searchText.lowercased()
        searchBar.text = lowerCaseSearchText
        if topTab.selectedSegmentIndex == 0{
            searchUsers(searchText: lowerCaseSearchText)
        }
        else if topTab.selectedSegmentIndex == 1{
            searchProducts(searchText: lowerCaseSearchText)
        }
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    

    
    @objc func segueToProfile(_ sender: UIButton){
        
        self.performSegue(withIdentifier: "ToProfile", sender: nil)
    }
    
    
    
    
    var selectedTemplateColor: String?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView{
            selectedTemplateColor = colorSections[indexPath.row]["ID"] as? String
            performSegue(withIdentifier: "toColorSection", sender: nil)
        }
        else if tableView == searchUsersTable{
            selectedUser = searchedUsers[indexPath.row]
            if selectedUser?.uid == userInfo.uid{
                tabBarController?.selectedIndex = 4
            }
            else{
                performSegue(withIdentifier: "ToFriend", sender: nil)
            }
        }
        else if tableView == searchProductsTable{
            productToOpen = searchedProducts[indexPath.row]
            performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tableView{
            
            return self.view.frame.height * factor
        }
        else if tableView == searchUsersTable{
            return 55
        }
        else if tableView == searchProductsTable{
            return 85
        }
        else{
            return UITableView.automaticDimension
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
        if let sectionVC = segue.destination as? ColorSectionVC{
            guard let color = selectedTemplateColor else{return}
            sectionVC.templateColor = color
        }
        else if let friend = segue.destination as? FriendVC{
            friend.friendInfo = selectedUser!
        }
    }
    
    
    
    /*
    func addDebitCard(){
        let form = STPPaymentCardTextField.init(frame: CGRect(x: 10, y: 0, width: self.view.frame.width - 20, height: 45))
    }
    */

    /*
    @IBAction func testCharge(_ sender: UIButton) {
     
        let data = [
            "product_id":"akskdjsj",
            "amount": 99999900,
            "source":"tok_visa",
            "customer_id": "cus_GXHvUh9RzbfEU0",
            "merchant_id": "acct_1FyBVRAIhu8eWpr1",
            "customer_uid" : "aR6FMc9OR2VmBUrHCk8l3KQIDPj1",
            "merchant_uid" : "fB6BIMoZ38gulk7Km0ReSIVceNe2"
            ] as [String : Any]
        Functions.functions().httpsCallable("createCharge").call(data, completion: { result, error in
            
            if error != nil{
                print(error?.localizedDescription ?? "")
                
                
            }
            else{
                
                
                
            }
        })
    }
 
 */
    

}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull ?? CFNull.self])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UITableView{
    func adjustForCenterBtn(footerColor: UIColor?, offset: CGFloat?, vc: UIViewController){
        if let tabBarVC = vc.tabBarController as? MainTabBarViewController{
            let view = UIView.init(frame: CGRect(x: 0, y: 0, width: vc.view.frame.width, height: (tabBarVC.button.frame.height / 2) + (offset ?? 0)))
            view.backgroundColor = footerColor ?? backgroundColor
            tableFooterView = view
        }
    }
}

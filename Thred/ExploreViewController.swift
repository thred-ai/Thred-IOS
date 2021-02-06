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
    let factor = CGFloat(0.35)
    print(factor)
    return factor
}

class Hashtag{
    
    var postsCount: Int?
    var array: [Product]?
    var display: String?
    var offset: CGFloat?
    var downloading: [String]?
    var tagDownloading: [String]?
    var blurred: Bool?
    var topPost: Product?
    
    init(postsCount: Int?, array: [Product]?, display: String?, offset: CGFloat?, downloading: [String]?, tagDownloading: [String]?, blurred: Bool?, topPost: Product?) {
        self.postsCount = postsCount
        self.array = array
        self.display = display
        self.offset = offset
        self.downloading = downloading
        self.tagDownloading = tagDownloading
        self.blurred = blurred
        self.topPost = topPost
    }
    
    convenience init() {
        self.init(postsCount: nil, array: nil, display: nil, offset: nil, downloading: nil, tagDownloading: nil, blurred: nil, topPost: nil)
    }
}

class Announcement{
    var timestamp: Date?
    var title: String?
    var info: String?
    var image: UIImage?
    var link: URL?
    
    init(timestamp: Date?, title: String?, info: String?, image: UIImage?, link: String?) {
        self.timestamp = timestamp
        self.info = info
        self.title = title
        self.image = image
        self.link = URL(string: link ?? "")
    }
    
    convenience init() {
        self.init(timestamp: nil, title: nil, info: nil, image: nil, link: nil)
    }
}

class ExploreViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{

    var hashTags = [Hashtag]()
    @IBOutlet var tableView: UITableView!
    
    
    var productToOpen: Product!
    var featuredHeader: ExploreTopView!
    var featuredProduct: Product!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(UINib(nibName: "ExploreColorCell", bundle: nil), forCellReuseIdentifier: "ExploreColorCell")
        featuredHeader = tableView.loadExploreTopHeaderFromNib()
        featuredHeader.vc = self
        searchBar.delegate = self
        
        navigationItem.titleView = searchBar
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
       
        tableView.addSubview(refresher)
        
        tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - (refresher.frame.size.height)), animated: true)
                
        refresher.beginRefreshing()
        refresher.animateRefresh()
        
        tableView.adjustForCenterBtn(footerColor: nil, offset: 5, vc: self)
        
        
        getTemplates{_ in
            self.isLoading = false
            refresher.endRefreshing()
        }
        
    
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if tableView == self.tableView{
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == self.tableView{
            return trendingLbl
        }
        else{
            return nil
        }
    }
    
    lazy var trendingLbl: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20))
        label.textAlignment = .center
        label.font = UIFont(name: "NexaW01-Heavy", size: label.font.pointSize)
        label.text = ""
        label.backgroundColor = .tertiarySystemBackground
        return label
    }()
    
    func getFeaturedPost(){
        
        guard let userUID = pUserInfo.uid else{return}
        Firestore.firestore().collectionGroup("Products").whereField("Public", isEqualTo: true).whereField("Timestamp", isGreaterThan: Timestamp(date: Date().adding(hours: -120))).order(by: "Timestamp").whereField("Blurred", isEqualTo: false).whereField("Has_Picture", isEqualTo: true).whereField("Available", isEqualTo: true).order(by: "Likes", descending: true).limit(to: 13).getDocuments(completion: { docs, error in
            
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
                    let productType = snap["Type"] as? String ?? defaultProductType
                    let displaySide = snap["Side"] as? String ?? "front"
                    let sides = snap["Sides"] as? [String] ?? ["Front"]

                    Firestore.firestore().collection("Users").document(uid).collection("Products").document(snap.documentID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                    
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
                        
                        let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: nil, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true, productType: productType, displaySide: displaySide, supportedSides: sides)
                        
                        self.featuredHeader.featuredView.featuredProducts.append(product)
                        
                        if self.featuredHeader.featuredView.featuredProducts.count == snaps.count{
                            self.featuredHeader.featuredView.numberOfItems = snaps.count
                            self.featuredHeader.featuredView.featuredProducts.sort(by: {$0.likes > $1.likes})
                            DispatchQueue.main.async {
                                self.featuredHeader.featuredView.collectionView.reloadData()
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
        search.placeholder = "Search on thred"
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
        
    }
    
    override func viewWillLayoutSubviews() {
        
        
        
        
        featuredHeader.frame.size.height = view.frame.width + 100
        featuredHeader.setFeaturedHeightConstraints(height: view.frame.width)
        featuredHeader.setNewsSectionHeightConstraints(height: 100)
        
    }
    
    func getAnnouncements(){
        Firestore.firestore().collection("Announcements").whereField("Active", isEqualTo: true).order(by: "Timestamp", descending: true).limit(to: 1).getDocuments(completion: { snaps, error in
            
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                self.announcements.removeAll()
                
                for doc in snaps?.documents ?? []{
                    let timestamp = (doc["Timestamp"] as? Timestamp)?.dateValue()
                    let title = doc["Title"] as? String
                    let info = (doc["Info"] as? String)?.replacingOccurrences(of: "\\n", with: "\n")
                    let link = doc["Link"] as? String
                    let announcement = Announcement(timestamp: timestamp, title: title, info: info, image: nil, link: link)
                    self.announcements.append(announcement)
                }
            }
            DispatchQueue.main.async {
                self.animateNewsSection()
            }
        })
    }
    
    func animateNewsSection(){
        
        featuredHeader.newsSection.titleView.isHidden = false

        if let announcement = announcements.first{
            featuredHeader.newsSection.titleLbl.text = announcement.title
            featuredHeader.newsSection.button.superview?.superview?.isHidden = false
            featuredHeader.newsSection.button.setTitle("View Details", for: .normal)
        }
        else{
            featuredHeader.newsSection.titleLbl.text = "Follow"
            featuredHeader.newsSection.button.superview?.superview?.isHidden = true
        }

    }
    
    var announcements = [Announcement]()
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        

        showCenterBtn()
        selectedUser = nil
        if let indexPath = searchUsersTable?.indexPathForSelectedRow{
            searchUsersTable?.deselectRow(at: indexPath, animated: true)
            searchUsersTable?.performBatchUpdates({
                searchUsersTable?.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        if let indexPath = searchProductsTable?.indexPathForSelectedRow{
            searchProductsTable?.deselectRow(at: indexPath, animated: true)
            searchProductsTable?.performBatchUpdates({
                searchProductsTable?.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        if let indexPath = tableView.indexPathForSelectedRow{
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.performBatchUpdates({
                tableView.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        if let indexPath = searchHashtagsTable?.indexPathForSelectedRow{
            searchHashtagsTable?.deselectRow(at: indexPath, animated: true)
            searchHashtagsTable?.performBatchUpdates({
                searchHashtagsTable?.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        if let indexPath = featuredHeader.featuredView.collectionView?.indexPathsForSelectedItems?.first{
            featuredHeader.featuredView.collectionView?.deselectItem(at: indexPath, animated: true)
            featuredHeader.featuredView.collectionView?.performBatchUpdates({
                featuredHeader.featuredView.collectionView?.reloadItems(at: [indexPath])
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
        for hashtag in hashTags{
            tableView.syncPostLikes(loadedProducts: hashtag.array ?? [], vc: self)
        }
        guard let colorSection = hashTags.first(where: {$0.display == productToOpen.templateColor}) else{return}
        guard let postArray = colorSection.array else{return}
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
                    self.featuredHeader.featuredView.featuredProducts.removeAll()
                    self.getTemplates{ error in
                        if error == nil{
                            self.hashTags.removeAll()
                            self.tableView.reloadData()
                        }
                        self.isLoading = false
                        sender.endRefreshing()
                    }
                }
            }
        }
        else{
            sender.endRefreshing()
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView{
            return hashTags.count
        }
        else if tableView == self.searchUsersTable{
            return searchedUsers.count
        }
        else if tableView == self.searchProductsTable{
            return searchedProducts.count
        }
        else if tableView == self.searchHashtagsTable{
            return searchedHashtags.count
        }
        return 0
    }
    
    func getTemplates(completed: @escaping (Error?) -> ()){
        
        guard let uid = pUserInfo.uid else{return}
        checkAuthStatus {
            self.refreshLists(userUID: uid){
                self.loadDesigns {
                    self.getFeaturedPost()
                    self.getAnnouncements()
                    self.loadHashtags(loadMore: false, completed: { error in
                        completed(error)
                    })
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == searchUsersTable || scrollView == searchProductsTable || scrollView == searchHashtagsTable{
            if searchUsersTable.numberOfRows(inSection: 0) != 0{
                searchBar.resignFirstResponder()
            }
            if searchProductsTable.numberOfRows(inSection: 0) != 0{
                searchBar.resignFirstResponder()
            }
            if searchHashtagsTable.numberOfRows(inSection: 0) != 0{
                searchBar.resignFirstResponder()
            }
        }
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) / 2{
            
            print("fromScroll")
            if !isLoading, canLoadMore{
                isLoading = true
                self.loadHashtags(loadMore: true, completed: {_ in
                    self.isLoading = false
                })
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 0 {
            canLoadMore = false
            // swipes from top to bottom of screen -> down
        } else {
            canLoadMore = true
            // swipes from bottom to top of screen -> up
        }
    }
    
    var canLoadMore = false
    var lastDoc: DocumentSnapshot?
    
    func loadHashtags(loadMore: Bool, completed: @escaping (Error?) -> ()){
        
        var query: Query?
        
        if loadMore, let doc = lastDoc{
            query = Firestore.firestore().collection("Tags").whereField("Blurred", isEqualTo: false).whereField("Posts_Count", isGreaterThan: 400).order(by: "Posts_Count", descending: true).limit(to: 8).start(afterDocument: doc)
        }
        else{
            query = Firestore.firestore().collection("Tags").whereField("Blurred", isEqualTo: false).whereField("Posts_Count", isGreaterThan: 400).order(by: "Posts_Count", descending: true).limit(to: 8)
        }
        query?.getDocuments(completion: { snaps, error in
            if error != nil{
                completed(error)
                print(error?.localizedDescription ?? "")
            }
            else{
                guard let docs = snaps?.documents, !docs.isEmpty
                    else{completed(Error.self as? Error); return}
                completed(nil)
                self.lastDoc = docs.last
                for doc in docs{
                    guard let postCount = doc["Posts_Count"] as? Int else{continue}
                    self.hashTags.append(Hashtag(postsCount: postCount, array: nil, display: doc.documentID, offset: 0, downloading: [], tagDownloading: [], blurred: false, topPost: nil))
                    self.tableView.performBatchUpdates({
                        self.tableView.insertRows(at: [IndexPath(row: self.hashTags.count - 1, section: 0)], with: .none)
                    }, completion: nil)
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let cell = cell as? ExploreColorCell{
            cell.collectionViewOffset = hashTags[indexPath.row].offset ?? 0
           
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ExploreColorCell{
            cell.postArray.removeAll()
            cell.collectionView.reloadData()
            if hashTags.indices.contains(indexPath.row){
                hashTags[indexPath.row].offset = cell.collectionViewOffset
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView{
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreColorCell", for: indexPath) as? ExploreColorCell
            
            let postSection = hashTags[indexPath.row]
            guard let sectionID = postSection.display else{return cell!}
            cell?.colorIcon.backgroundColor = nil
            cell?.exploreVC = nil
            cell?.templateColor = nil
            cell?.colorNameLbl.text = nil
            cell?.numPostsLbl.text = nil
            cell?.numPostsLbl.attributedText = nil
            cell?.postArray = nil
            
            //cell?.colorIcon.backgroundColor = UIColor(named: postSection["ID"] as? String ?? "null")
            cell?.colorNameLbl.text = sectionID
            cell?.exploreVC = self
            cell?.templateColor = sectionID //problem
            
            if let postCount = postSection.postsCount{
                cell?.numPostsLbl.setArrow(name: "\(postCount.kmFormatted)")
            }
            
            if let postArray = postSection.array{
                cell?.postArray = postArray
            }
            
            var downloading = postSection.tagDownloading
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
            guard searchedUsers.indices.contains(indexPath.row) else{return cell!}
            let user = self.searchedUsers[indexPath.row]
            cell?.userImageView.image = nil
            cell?.fullnameLbl.text = nil
            cell?.usernameLbl.text = nil
            cell?.fullnameLbl.attributedText = nil
            
            
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
            if user.verified{
                cell?.fullnameLbl.setVerified(name: user.fullName ?? "")
            }
            return cell!
        }
        else if tableView == self.searchHashtagsTable{
            
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "hashtagCell")
            guard searchedHashtags.indices.contains(indexPath.row) else{return cell}
            let hashtag = self.searchedHashtags[indexPath.row]
            guard let tag = hashtag.display, let numPosts = hashtag.postsCount else{return cell}
            cell.backgroundColor = .clear
            
            var grammar = ""
            var numString = "\(numPosts.kmFormatted)"
            
            if numPosts != 1{
                grammar = "s"
                if numPosts == 0{
                    numString = "No"
                }
            }
            
            cell.textLabel?.font = UIFont(name: "NexaW01-Heavy", size: cell.textLabel?.font.pointSize ?? 16)
            cell.detailTextLabel?.font = UIFont(name: "NexaW01-Regular", size: cell.detailTextLabel?.font.pointSize ?? 14)
            cell.textLabel?.text = "#\(tag)"
            cell.detailTextLabel?.text = "\(numString) Post\(grammar)"
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchProductCell", for: indexPath) as? SearchProductTableViewCell
            guard searchedProducts.indices.contains(indexPath.row) else{return cell!}
            let product = searchedProducts[indexPath.row]
            cell?.productImageView.image = nil
            cell?.priceLbl.text = nil
            cell?.likesLbl.text = nil
            cell?.productNameLbl.text = nil
            cell?.productImageView.backgroundColor = .secondarySystemBackground
            cell?.quantityView.isHidden = true
            cell?.sizingLbl.isHidden = true
            cell?.likesView.isHidden = false

            
            DispatchQueue(label: "explore").async {
                var prefix = ""
                if product.displaySide == "back" || product.displaySide == "Back"{
                    prefix = "BACK_"
                }
                
                let thumbnail = "thumbnail_"
                
                let picString = "\(thumbnail)\(prefix)\(product.productID)"
                if let dp = cache.imageFromMemoryCache(forKey: picString){
                    DispatchQueue.main.async {
                        cell?.productImageView.image = dp
                    }
                }
            }
            let color = all.tees.first(where: {$0.productCode == product.productType})?.colors.first(where: {$0.code == product.templateColor})?.getColor()

            cell?.productImageView.backgroundColor = color
            cell?.productNameLbl.text = product.name
            
            cell?.priceLbl.text = product.price?.formatPrice()

            cell?.likesLbl.text = all.tees.first(where: {$0.productCode == product.productType})?.info

            return cell!
        }
    }
    
    
   
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

    }

    
    var topTab: UISegmentedControl!
    var searchUsersTable: UITableView!
    var searchProductsTable: UITableView!
    var searchHashtagsTable: UITableView!

           
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
        topTab.insertSegment(withTitle: "Hashtags", at: 1, animated: false)
        topTab.insertSegment(withTitle: "Threds", at: 2, animated: false)

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
        
        searchHashtagsTable = UITableView(frame: CGRect(x: 0, y: topTab.frame.maxY + 5, width: view.frame.width, height: view.frame.height - topTab.frame.maxY - 5))
        searchHashtagsTable.separatorStyle = .none
        searchHashtagsTable.delegate = self
        searchHashtagsTable.dataSource = self
        searchHashtagsTable.backgroundColor = .clear
        
        searchProductsTable = UITableView(frame: CGRect(x: 0, y: topTab.frame.maxY + 5, width: view.frame.width, height: view.frame.height - topTab.frame.maxY - 5))
        searchProductsTable.separatorStyle = .none
        searchProductsTable.register(UINib(nibName: "SearchProductTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchProductCell")
        searchProductsTable.delegate = self
        searchProductsTable.dataSource = self
        searchProductsTable.backgroundColor = .clear
        
        view.addSubview(topTab)
        view.addSubview(searchUsersTable)
        view.addSubview(searchHashtagsTable)
        view.addSubview(searchProductsTable)
        
        searchHashtagsTable.isHidden = true
        searchProductsTable.isHidden = true

        return view
    }()
    
    var searchedHashtags = [Hashtag]()
    
    @objc func switchedSegment(_ sender: UISegmentedControl){
        
        if sender.selectedSegmentIndex == 0{
            searchProductsTable.isHidden = true
            searchHashtagsTable.isHidden = true
            searchUsersTable.isHidden = false
            searchedUsers.removeAll()
            searchUsersTable.reloadData()
            
            if let text = searchBar.text?.lowercased(), !text.isEmpty{
                searchUsers(searchText: text)
            }
        }
        else if sender.selectedSegmentIndex == 1{
            searchProductsTable.isHidden = true
            searchUsersTable.isHidden = true
            searchHashtagsTable.isHidden = false
            searchedHashtags.removeAll()
            searchHashtagsTable.reloadData()
            
            if let text = searchBar.text, !text.isEmpty{
                searchHashtags(searchText: text)
            }
        }
        else{
            searchUsersTable.isHidden = true
            searchHashtagsTable.isHidden = true
            searchProductsTable.isHidden = false
            searchedProducts.removeAll()
            searchProductsTable.reloadData()
            
            if let text = searchBar.text?.lowercased(), !text.isEmpty{
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
                                let verified = document["Verified"] as? Bool ?? false

                                if pUserInfo.usersBlocking.contains(uid){
                                    if document == documents.first, documents.count < 1{
                                        self.searchedUsers.removeAll()
                                    }
                                    continue
                                }
                                else{
                                    if document == documents.first{
                                        self.searchedUsers.removeAll()
                                    }
                                }
                                
                                let user = UserInfo(uid: uid, dp: nil, dpID: dpLink, username: username, fullName: fullname, bio: bio, notifID: nil, userFollowing: userFollowing ?? [], userLiked: [], followerCount: followerCount ?? 0, postCount: postCount ?? 0, followingCount: followingCount ?? 0, usersBlocking: usersBlocking ?? [], profileLink: nil, verified: verified)

                                if uid == pUserInfo.uid{
                                    user.dp = pUserInfo.dp
                                    user.dpID = pUserInfo.dpID
                                    self.searchedUsers.append(user)
                                    self.searchUsersTable.reloadData()
                                    continue
                                }
                                
                                if !self.searchedUsers.contains(where: {$0.uid == document.documentID}){
                                    self.searchedUsers.append(user)
                                }
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
    
    func searchHashtags(searchText: String){
        if searchText == ""{
            searchedHashtags.removeAll()
            searchHashtagsTable.reloadData()
            searchHashtagsTable.separatorStyle = .none
            //self.getFollowers()
        }
        else{
            //searchBar.isLoading = true
            Firestore.firestore().collection("Tags").whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: searchText).whereField(FieldPath.documentID(), isLessThanOrEqualTo: searchText + "\u{f8ff}").limit(to: 8).getDocuments(completion: { query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    self.searchedHashtags.removeAll()
                    if let documents = query?.documents{
                        if documents.count != 0{
                            self.searchHashtagsTable.separatorStyle = .singleLine
                            for doc in documents{
                                guard let postCount = doc["Posts_Count"] as? Int else{continue}
                                let blurred = doc["Blurred"] as? Bool ?? false
                                self.searchedHashtags.append(Hashtag(postsCount: postCount, array: nil, display: doc.documentID, offset: 0, downloading: [], tagDownloading: [], blurred: blurred, topPost: nil))
                            }
                            self.searchHashtagsTable.reloadData()
                        }
                        else{
                            self.searchHashtagsTable.separatorStyle = .none
                            self.searchHashtagsTable.reloadData()
                        }
                    }
                }
            })
        }
    }
    
    
    func searchProducts(searchText: String){
        guard let userUID = pUserInfo.uid else{return}
        if searchText == ""{
            searchedProducts.removeAll()
            searchProductsTable.reloadData()
            //self.getFollowers()
        }
        else{
            //searchBar.isLoading = true
            Firestore.firestore().collectionGroup("Products")
                .whereField("Search_Name", isGreaterThanOrEqualTo: searchText).whereField("Search_Name", isLessThanOrEqualTo: searchText + "\u{f8ff}").whereField("Has_Picture", isEqualTo: true).whereField("Public", isEqualTo: true).whereField("Available", isEqualTo: true).limit(to: 8).getDocuments(completion: { query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    
                    self.searchedProducts.removeAll()
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{
                                
                                let timestamp = (document["Timestamp"] as? Timestamp)?.dateValue()
                                
                                guard let uid = document["UID"] as? String else{
                                    continue}
                                if pUserInfo.usersBlocking.contains(uid){
                                    continue
                                }
                                let description = document["Description"] as? String
                                let name = document["Name"] as? String
                                let blurred = document["Blurred"] as? Bool
                                let templateColor = document["Template_Color"] as? String
                                let likes = document["Likes"] as? Int
                                guard let priceCents = (document["Price_Cents"] as? Double) else{continue}
                                let comments = ((document["Comments"]) as? Int) ?? 0
                                let productID = document.documentID
                                let productType = document["Type"] as? String ?? defaultProductType
                                let displaySide = document["Side"] as? String ?? "front"
                                let sides = document["Sides"] as? [String] ?? ["Front"]

                                let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: productID, description: description, productID: productID, timestamp: timestamp, index: 0, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: pUserInfo.userLiked.contains(productID), designImage: nil, comments: comments, link: nil, isAvailable: true, isPublic: true, productType: productType, displaySide: displaySide, supportedSides: sides)

                                Firestore.firestore().collection("Users").document(uid).collection("Products").document(productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                                
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        pUserInfo.userLiked.removeAll(where: {$0 == productID})
                                        if let likeDocs = snapLikes?.documents{
                                            if likeDocs.isEmpty{
                                                product.liked = false
                                            }
                                            else{
                                                product.liked = true
                                                if !(pUserInfo.userLiked.contains(productID)){
                                                    pUserInfo.userLiked.append(productID)
                                                }
                                            }
                                        }
                                        else{
                                            product.liked = false
                                        }
                                    }
                                    if !self.searchedProducts.contains(where: {$0.productID == document.documentID}){
                                        self.searchedProducts.append(product)
                                    }
                                    self.searchedProducts.sort(by: {$0.likes > $1.likes})
                                    self.searchProductsTable.reloadData()
                                    var prefix = ""
                                    if displaySide == "back" || displaySide == "Back"{
                                        prefix = "BACK_"
                                    }
                                    
                                    let thumbnail = "thumbnail_"
                                    
                                    let picString = "\(thumbnail)\(prefix)\(productID)"
                                    
                                    let ref = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + productID + "/" + picString + ".png")
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
                                                        cache.storeImage(toMemory: image, forKey: picString)
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
        
        if topTab.selectedSegmentIndex == 0{
            let lowerCaseSearchText = searchText.lowercased()
            searchBar.text = lowerCaseSearchText
            searchUsers(searchText: lowerCaseSearchText)
        }
        else if topTab.selectedSegmentIndex == 1{
            searchHashtags(searchText: searchBar.text ?? "")
        }
        else if topTab.selectedSegmentIndex == 2{
            let lowerCaseSearchText = searchText.lowercased()
            searchBar.text = lowerCaseSearchText
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
    
    
    
    
    var selectedHashtag = Hashtag()
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView{
            selectedHashtag = hashTags[indexPath.row]
            performSegue(withIdentifier: "toColorSection", sender: nil)
        }
        else if tableView == searchUsersTable{
            selectedUser = searchedUsers[indexPath.row]
            if selectedUser?.uid == pUserInfo.uid{
                tabBarController?.selectedIndex = 4
            }
            else{
                performSegue(withIdentifier: "ToFriend", sender: nil)
            }
        }
        else if tableView == searchHashtagsTable{
            guard searchedHashtags[indexPath.row].postsCount != 0 else{
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
            selectedHashtag = searchedHashtags[indexPath.row]
            performSegue(withIdentifier: "toColorSection", sender: nil)
            
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
            let hashtag = selectedHashtag
            sectionVC.hashtag = hashtag
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

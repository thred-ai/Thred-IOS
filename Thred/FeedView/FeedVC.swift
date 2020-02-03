//
//  FeedVC.swift
//  Thred
//
//  Created by Artak on 2019-10-23.
//  Copyright © 2019 ArtaCorp. All rights reserved.
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
        return true
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
    var fromCache = Bool()
    var price: Double? = 0
    var name: String? = nil

    
    init(uid: String, picID: String?, description: String?, fullName: String?, username: String?, productID: String, userImageID: String?, timestamp: Date!, index: Int!, timestampDiff: String!, fromCache: Bool, price: Double?, name: String?) {
        
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
        self.fromCache = fromCache
        self.price = price
        self.name = name
    }
    
    convenience init() {
        self.init(uid: "", picID: nil, description: nil, fullName: nil, username: "", productID: "", userImageID: nil, timestamp: nil,  index: nil, timestampDiff: nil, fromCache: false, price: nil, name: nil)
    }
    
}

class FeedVC: UITableViewController, UISearchBarDelegate {
    
    var loadedProducts = [Product]()
    var isLoading = Bool()
    let uid = UserDefaults.standard.string(forKey: "UID")
    var downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)

    var tokens = [String]()
    
    var downloadCount = 0
    
    struct TimeUnits{
        
        let stringUnits: [String] = []
        let cmpntUnits: [DateComponents] = []
        
    }
    
    private struct Const {
        /// Image height/width for Large NavBar state
        static let ImageSizeForLargeState: CGFloat = 60
        /// Margin from right anchor of safe area to right anchor of Image
        static let ImageRightMargin: CGFloat = 20 //
        /// Margin from bottom anchor of NavBar to bottom anchor of Image for Large NavBar state
        static let ImageBottomMarginForLargeState: CGFloat = 15 //
        /// Margin from bottom anchor of NavBar to bottom anchor of Image for Small NavBar state
        static let ImageBottomMarginForSmallState: CGFloat = 15
        /// Image height/width for Small NavBar state
        static let ImageSizeForSmallState: CGFloat = 60
        /// Height of NavBar for Small state. Usually it's just 44
        static let NavBarHeightSmallState: CGFloat = 44
        /// Height of NavBar for Large state. Usually it's just 96.5 but if you have a custom font for the title, please make sure to edit this value since it changes the height for Large state of NavBar
        static let NavBarHeightLargeState: CGFloat = 96.5
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView{
            return loadedProducts.count
        }
        else{
            return loadedUsers.count
        }
    }
    
    override func awakeFromNib() {
        loadUserInfo()
    }
    
    lazy var rightNavItems: UIBarButtonItem? = {
     

        guard let navigationBar = navigationController?.navigationBar else { return nil }

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let heightToSet = navigationBar.frame.height - 10
        
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: heightToSet),
        ])
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .fill
        stack.distribution = .fillEqually
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        ])
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: heightToSet, height: heightToSet))
        button.accessibilityIdentifier = "ProfileBtn"
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        button.layer.borderWidth = 2
        button.addTarget(self, action: #selector(segueToProfile(_:)), for: .touchUpInside)
        button.setImage(userInfo.dp, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: heightToSet),
            button.widthAnchor.constraint(equalTo: button.heightAnchor)
        ])
        
        let cancelBtn = UIButton()
        cancelBtn.accessibilityIdentifier = "CancelBtn"
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.setTitleColor(ColorCompatibility.label, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelSearch), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelBtn.heightAnchor.constraint(equalToConstant: heightToSet),
            cancelBtn.widthAnchor.constraint(greaterThanOrEqualTo: cancelBtn.heightAnchor)
        ])

        stack.addArrangedSubview(button)
        stack.addArrangedSubview(cancelBtn)
        cancelBtn.isHidden = true
        
        return UIBarButtonItem(customView: view)
    }()
    
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let button = self.getProfileBtn(){
            button.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
    }
    
    func getProfileBtn() -> UIButton?{
        guard let view = rightNavItems?.customView
            else{return nil}
        guard let stack = view.subviews.first as? UIStackView
            else{return nil}
        guard let button = stack.arrangedSubviews.first(where: {$0.accessibilityIdentifier == "ProfileBtn"}) as? UIButton
            else{return nil}
        return button
    }
    
    private func setupUI(image: UIImage) {

        if let button = getProfileBtn(){
            button.setImage(image, for: .normal)
            button.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
        
        navigationItem.setRightBarButton(rightNavItems, animated: false)

    }
    
    
    func showCancelBtn(){
        guard let buttons = (self.rightNavItems?.customView?.subviews.first as? UIStackView)?.arrangedSubviews as? [UIButton] else{
            return}
        
        let profileBtn = buttons.first(where: {$0.accessibilityIdentifier == "ProfileBtn"})
        let cancelBtn = buttons.first(where: {$0.accessibilityIdentifier == "CancelBtn"})

        profileBtn?.isHidden = true
        
        cancelBtn?.alpha = 0.0
        UIView.animate(withDuration: 0.1, animations: {
            cancelBtn?.isHidden = false
            cancelBtn?.alpha = 1.0
            self.navigationController?.navigationBar.setNeedsLayout()
            self.navigationController?.navigationBar.layoutIfNeeded()
        })
    }
    
    func hideCancelBtn(){
        guard let buttons = (self.rightNavItems?.customView?.subviews.first as? UIStackView)?.arrangedSubviews as? [UIButton] else{
            return}
        
        let profileBtn = buttons.first(where: {$0.accessibilityIdentifier == "ProfileBtn"})
        let cancelBtn = buttons.first(where: {$0.accessibilityIdentifier == "CancelBtn"})

        cancelBtn?.isHidden = true
        profileBtn?.alpha = 0.0
        UIView.animate(withDuration: 0.1, animations: {
            profileBtn?.isHidden = false
            profileBtn?.alpha = 1.0
            self.navigationController?.navigationBar.setNeedsLayout()
            self.navigationController?.navigationBar.layoutIfNeeded()
        })
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        FeedVC.searchTable.isHidden = false
        tableView.isScrollEnabled = false
        showCancelBtn()
        UIView.animate(withDuration: 0.1, animations: {
            FeedVC.searchTable.alpha = 1.0
        }, completion: {(finished : Bool) in })
    }
    
    @objc func cancelSearch(){
        FeedVC.searchBar.resignFirstResponder()
        self.loadedUsers.removeAll()
        FeedVC.searchTable.reloadData()
        FeedVC.searchBar.text?.removeAll()
        UIView.animate(withDuration: 0.1, animations: {
            
            FeedVC.searchTable.alpha = 0.0
        }, completion: {(finished : Bool) in
            FeedVC.searchTable.isHidden = true
            self.tableView.isScrollEnabled = true
        })
        hideCancelBtn()
    }
    
    
    
    var loadedUsers = [UserInfo]()
    var selectedUser: UserInfo? = UserInfo()
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        
        
        if searchText == ""{
            loadedUsers.removeAll()
            FeedVC.searchTable.reloadData()
            //self.getFollowers()
            
        }
        else{
            //searchBar.isLoading = true
            let lowerCaseSearchText = searchText.lowercased()
            Firestore.firestore().collection("Users").whereField("Username", isGreaterThanOrEqualTo: lowerCaseSearchText).whereField("Username", isLessThanOrEqualTo: lowerCaseSearchText + "\u{f8ff}").limit(to: 8).getDocuments(completion: {[weak self] query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    self?.loadedUsers.removeAll()
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{
                                let uid = document.documentID
                                let username = document["Username"] as? String
                                let fullname = document["Full Name"] as? String
                                let bio = document["Bio"] as? String
                                let dpLink = document["ProfilePicID"] as? String
                                let notifID = document["Notification ID"] as? String
                                
                                let user = UserInfo(uid: uid, dp: nil, dpID: dpLink ?? "nil", username: username ?? "null", fullName: fullname ?? "null", bio: bio ?? "", notifID: notifID ?? "", userFollowing: nil)

                                if uid == userInfo.uid{
                                    user.dp = userInfo.dp
                                    user.dpID = userInfo.dpID
                                    self?.loadedUsers.append(user)
                                    FeedVC.searchTable.reloadData()
                                    continue
                                }
                                
                                self?.loadedUsers.append(user)
                                FeedVC.searchTable.reloadData()
                                let ref = Storage.storage().reference()
                                ref.child("Users/" + uid + "/" + "profile_pic-" + (dpLink ?? "null") +
                                    ".jpeg").downloadURL(completion: { url, error in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        
                                        self?.downloader.requestImage(with: url, options: [.scaleDownLargeImages, .refreshCached], context: nil, progress: nil, completed: {[weak self] (image, data, error, finished) in
                                            if error != nil{
                                                print(error?.localizedDescription ?? "")
                                                return
                                            }
                                            else{
                                                user.dp = image
                                                if let index = self?.loadedUsers.firstIndex(where: {$0.uid == uid}){
                                                    FeedVC.searchTable.performBatchUpdates({
                                                        FeedVC.searchTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                                    }, completion: nil)
                                                }
                                            }
                                        })
                                    }
                                })
                            }
                        }
                        else{
                            FeedVC.searchTable.reloadData() //No Results
                        }
                    }
                }
            })
        }
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
    
    
    
    
    @objc func segueToProfile(_ sender: UIButton){
        
        self.performSegue(withIdentifier: "ToProfile", sender: nil)
    }
        
    
    var downloadingProfiles = [String]()

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView{
            let user = self.loadedProducts[indexPath.row]
            let cell = tableView.setPictureCell(indexPath: indexPath, user: user, productLocation: self)
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as? SearchUserTableViewCell
            let user = self.loadedUsers[indexPath.row]
            cell?.userImageView.image = nil

            if let dp = user.dp{
                cell?.spinner.isHidden = true
                cell?.userImageView.image = dp
            }
            else{
                cell?.spinner.isHidden = false
                cell?.spinner.animate()
            }
            cell?.usernameLbl.text = "@" + user.username
            cell?.fullnameLbl.text = user.fullName
            return cell!
        }
    }
    
    override func didReceiveMemoryWarning() {
        
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
            if sender.isRefreshing{
                sender.animateRefresh()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if !self.myFollowing.isEmpty{
                    self.downloadProducts(){
                        self.isLoading = false
                        sender.endRefreshing()
                    }
                }
                else{
                    self.isLoading = false
                    sender.endRefreshing()
                }
            }
        }
        else{
        }
    }
    
    func downloadProducts(completed: @escaping () -> ()){
        getProducts(fromInterval: nil) {[weak self] hasDiffproducts, snapDocs in
            completed()
            if hasDiffproducts ?? false{
                self?.loadedProducts.removeAll()
                self?.cellHeights.removeAll()
                self?.tableView.reloadData()
            }
            else{
                for i in 0..<(self?.loadedProducts.count ?? 0){
                    self?.loadedProducts[i].fromCache = false
                }
                if let indexPaths = self?.tableView.indexPathsForVisibleRows{
                    self?.tableView.performBatchUpdates({
                        self?.tableView.reloadRows(at: indexPaths, with: .none)
                    }, completion: nil)
                }
            }
        }
    }
    
    @IBAction func unwindToFeed(segue:  UIStoryboardSegue) {
        
        if let button = getProfileBtn(){
            button.setImage(userInfo.dp, for: .normal)
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        
    }
    
    
    
    
    var myFollowing = userInfo.userFollowing ?? []

 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.allowsSelection = false
        //cache.config.maxMemoryCost = 15 * 1024 * 1024

        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        tableView.register(UINib(nibName: "ProductWithTextCell", bundle: nil), forCellReuseIdentifier: "TextProduct")
        FeedVC.searchTable.delegate = self
        FeedVC.searchTable.dataSource = self
        setSearchTableConstraints()
        FeedVC.searchBar.delegate = self
        FeedVC.searchTable.register(UINib(nibName: "SearchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "search")
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

        let image = userInfo.dp
        
        setupUI(image: image!)
        navigationItem.titleView = FeedVC.searchBar
        
        
        //UserDefaults.standard.set("vK39Da3RIGVGsgBgpdkj0CWdtdW2", forKey: "UID") //Arta
        //UserDefaults.standard.set("tl1oOs1NXdeHsium7ZygweBc7YO2", forKey: "UID") //Arvin
        //UserDefaults.standard.set("te7lsnwiPUMyj85O4Q5Tkvuu3VH3", forKey: "UID") //Dad
        
        if userInfo.uid == "vK39Da3RIGVGsgBgpdkj0CWdtdW2"{
            myFollowing.append("tl1oOs1NXdeHsium7ZygweBc7YO2") //Arta
            myFollowing.append("te7lsnwiPUMyj85O4Q5Tkvuu3VH3")
        }
        else if userInfo.uid == "tl1oOs1NXdeHsium7ZygweBc7YO2"{ //Arvin
            myFollowing.append("vK39Da3RIGVGsgBgpdkj0CWdtdW2")
            myFollowing.append("te7lsnwiPUMyj85O4Q5Tkvuu3VH3")
        }
        else if userInfo.uid == "te7lsnwiPUMyj85O4Q5Tkvuu3VH3"{ //Dad
            myFollowing.append("vK39Da3RIGVGsgBgpdkj0CWdtdW2")
            myFollowing.append("tl1oOs1NXdeHsium7ZygweBc7YO2")
        }
        
        
        
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
                    print("hey")
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
        
        // Do any additional setup after loading the view.
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

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
    var currentproductsJSON: [DocumentSnapshot]!

    
    func getProducts(fromInterval: Date?, completed: @escaping (Bool?, [DocumentSnapshot]?) -> ()){
        
    

        guard let searchDate = currentDate(asString: false, dateToUse: Date(), toFirestoreFormat: true).0 else{return}
        //REMOVE LATER
        query = nil
        if fromInterval == nil{
            query = Firestore.firestore().collectionGroup("Posts").whereField("UID", in: myFollowing).whereField("Timestamp", isLessThanOrEqualTo: searchDate).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        if let last = fromInterval{
            query = Firestore.firestore().collectionGroup("Posts").whereField("UID", in: myFollowing).whereField("Timestamp", isLessThan: last).limit(to: 8).order(by: "Timestamp", descending: true)
        }
        
        query.getDocuments(completion: {[weak self] (snapDocuments, err) in
            
            if err != nil {
                print("Error getting documents: \(err!)")
                completed(false, nil)
                return
            }
            else {
                if snapDocuments?.isEmpty ?? true{
                    completed(false, nil)
                }
                else{
                    guard let snaps = snapDocuments?.documents else {return}
                    if snapDocuments?.metadata.isFromCache ?? false{
                        completed(false, snaps)
                    }
                    else{
                        switch fromInterval{
                        case .none:
                            let isSame = snaps.compactMap({$0.documentID}) == self?.loadedProducts.compactMap({$0.productID})

                            self?.loadedProducts.removeOldFeedPosts(snaps: snaps) {
                                if isSame{
                                    completed(false, snaps)
                                }
                                else{
                                    completed(true, snaps)
                                    self?.sortDownloadedProducts(snaps: snaps)
                                }
                            }
                        default:
                            completed(true, snaps)
                            self?.sortDownloadedProducts(snaps: snaps)
                        }
                    }
                }
            }
        })
    }
    
    func sortDownloadedProducts(snaps: [QueryDocumentSnapshot]){
        for (index, snap) in snaps.enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
            if !loadedProducts.contains(where: {$0.productID == snap.documentID}){
                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                let uid = snap["UID"] as! String
                let description = snap["Description"] as? String
                let name = snap["Name"] as? String
                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                               
                               
                loadedProducts.append(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: index, timestampDiff: nil, fromCache: false, price: priceCents / 100, name: name))
                
                
                tableView.performBatchUpdates({
                    self.tableView.insertRows(at: [IndexPath(row: self.loadedProducts.count - 1, section: 0)], with: .none)
                }, completion: { finished in
                    if finished{
                       
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
        return cellHeights[indexPath] ?? 100
    }
    
    
    
    //LOAD COMMENTER'S PROFILE PICTURE INTO THE COMMENT CELL
    
    var productToOpen = Product()

    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        selectedUser = nil

        if let indexPath = FeedVC.searchTable.indexPathForSelectedRow{
            FeedVC.searchTable.deselectRow(at: indexPath, animated: true)
        }
        
        if loadedUsers.contains(where: {$0.username.isEmpty || $0.fullName.isEmpty || $0.dp == nil}){
            loadedUsers.removeAll()
            FeedVC.searchBar.text?.removeAll()
            DispatchQueue.main.async {
                FeedVC.searchTable.reloadData()
            }
        }
    }
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView{
            productToOpen = loadedProducts[indexPath.row]
            performSegue(withIdentifier: "ToProduct", sender: nil)
        }
        else if tableView == FeedVC.searchTable{
            selectedUser = loadedUsers[indexPath.row]
            if selectedUser?.uid == userInfo.uid{
                performSegue(withIdentifier: "toProfileFromSearch", sender: nil)
            }
            else{
                performSegue(withIdentifier: "ToFriend", sender: nil)
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.destination as? UINavigationController != nil{

        }
        else if let friend = segue.destination as? FriendVC{
            friend.friendInfo = selectedUser!
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
    
    func loadUserInfo(){
        
        UserDefaults.standard.set("aR6FMc9OR2VmBUrHCk8l3KQIDPj1", forKey: "UID") //Arta
        //UserDefaults.standard.set("tl1oOs1NXdeHsium7ZygweBc7YO2", forKey: "UID") //Arvin
        //UserDefaults.standard.set("te7lsnwiPUMyj85O4Q5Tkvuu3VH3", forKey: "UID") //Dad

        let uid = UserDefaults.standard.string(forKey: "UID")!
        userInfo.uid = uid

        let username = UserDefaults.standard.string(forKey: "USERNAME") ?? "null"
        userInfo.username = username
        let fullname = UserDefaults.standard.string(forKey: "FULLNAME") ?? "null"
        userInfo.fullName = fullname

        if let bio = UserDefaults.standard.string(forKey: "BIO"){
            userInfo.bio = bio
        }
        let dpID = UserDefaults.standard.string(forKey: "DP_ID") ?? "default"
        userInfo.dpID = dpID
        let profilePic = cache.imageFromDiskCache(forKey: dpID) ?? defaultDP
        userInfo.dp = profilePic
        
        if let notifID = UserDefaults.standard.string(forKey: "NOTIF_ID"){
            userInfo.notifID = notifID
        }
    }
}

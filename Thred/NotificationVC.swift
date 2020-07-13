//
//  NotificationVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-14.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import ColorCompatibility
import FirebaseFirestore


class UserNotification: Codable{
    
    var notifID: String!
    var uid: String!
    var notifType: String!
    var timestamp: Date!
    var timestampDiff: String!
    var username: String!
    var picID: String!
    var commentMessage: String?
    var commentID: String?
    var shouldShowDP: Bool!
    var templateColor: String!
    var product: Product!
    var userInfo: UserInfo!
    var deleted: Bool!
    
    init(notifID: String!, uid: String!, notifType: String!, timestamp: Date!, username: String!, picID: String!, shouldShowDP: Bool!, templateColor: String!, timestampDiff: String!, commentMessage: String?, commentID: String?, deleted: Bool!) {
        self.notifID = notifID
        self.uid = uid
        self.notifType = notifType
        self.timestamp = timestamp
        self.username = username
        self.picID = picID
        self.shouldShowDP = shouldShowDP
        self.templateColor = templateColor
        self.timestampDiff = timestampDiff
        self.commentMessage = commentMessage
        self.commentID = commentID
        self.deleted = deleted
    }
    
    convenience init(){
        self.init(notifID: nil, uid: nil, notifType: nil, timestamp: nil, username: nil, picID: nil, shouldShowDP: nil, templateColor: nil, timestampDiff: nil, commentMessage: nil, commentID: nil, deleted: nil)
    }
}

class Order{
    
    var orderID: String!
    var timestamp: Date!
    var products: [ProductInCart]!
    var status: String!
    var intents: [[String : String]]!
    var shippingIntent: String?
    var shippingCost: Double?
    var totalCost: Double?
    var tax: Double?
    var subtotal: Double?
    var address: Address!
    var trackingNumber: String?
    
    
    var canCancel: Bool{
        get{
            guard status != nil else{return false}
            return status == "confirmed"
        }
    }
    
    init(orderID: String?, timestamp: Date?, products: [ProductInCart], status: String!, intents: [[String : String]], shippingIntent: String?, shippingCost: Double?, subtotal: Double?, tax: Double?, totalCost: Double?, address: Address?, trackingNumber: String?) {
        self.orderID = orderID
        self.timestamp = timestamp
        self.products = products
        self.status = status
        self.shippingCost = shippingCost
        self.intents = intents
        self.shippingIntent = shippingIntent
        self.subtotal = subtotal
        self.tax = tax
        self.totalCost = totalCost
        self.address = address
        self.trackingNumber = trackingNumber
    }
    
    convenience init(){
        self.init(orderID: nil, timestamp: nil, products: [], status: nil, intents: [], shippingIntent: nil, shippingCost: nil, subtotal: nil, tax: nil, totalCost: nil, address: nil, trackingNumber: nil)
    }
}

class NotificationVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var notifications = [UserNotification]()
    var orders = [Order]()
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    lazy var ordersTableView: UITableView = {
        let tableView = UITableView.init(frame: self.tableView.frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == ordersTableView{
            if orders.isEmpty{
                return 1
            }
            else{
                return orders.count
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == ordersTableView{
            if orders.isEmpty{
                return 0
            }
            if orders[section].products.count == 0{
                
            }
            return orders[section].products.count
        }
        return notifications.count
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.tabBarItem.badgeValue = nil
        self.navigationController?.tabBarItem.badgeColor = nil
        UIApplication.shared.applicationIconBadgeNumber = 0 // For Clear Badge Counts
    }
    
    var isLoadingNotifs = false
    var isLoadingOrders = false
    var lastDoc: DocumentSnapshot!
    var fullOrder: Order!

    
    func getOrders(completed: @escaping () -> ()){
        
        var query: Query!
        guard let uid = userInfo.uid else{return}

        if let last = lastDoc{
            query = Firestore.firestore().collection("Users/\(uid)/Orders").order(by: "timestamp", descending: true).start(afterDocument: last)
        }
        else{
            query = Firestore.firestore().collection("Users/\(uid)/Orders").order(by: "timestamp", descending: true)
        }
        query?.getDocuments(completion: { snaps, error in
            
            if let err = error{
                print(err.localizedDescription)
                completed()
            }
            else{
                                
                guard let docs = snaps?.documents, !docs.isEmpty
                    else{
                        
                        completed(); return }
                var localLoaded = [Order]()
                var downloaded = 0

                self.lastDoc = docs.last
                var docCount = docs.count
                for doc in docs{
                    let timestamp = (doc["timestamp"] as? Timestamp)?.dateValue()
                    let status = doc["status"] as? String ?? "cancelled"
                    let intents = doc["order_intents"] as? [[String : String]] ?? [[:]]
                    let shippingIntent = doc["shipping_intent"] as? String
                    let trackingNumber = doc["tracking_id"] as? String
                    let shippingCost = (doc["shipping_cost"] as? Double ?? 0.00) / 100
                    let tax = doc["tax"] as? Double ?? 1.0
                    var subtotal = 0.0
                    
                    guard
                        let address = doc["delivery_address"] as? [String : Any],
                        let street = address["street_address"] as? String,
                        let city = address["city"] as? String,
                        let country = address["country"] as? String,
                        let postalCode = address["postal_code"] as? String,
                        let area = address["admin_area"] as? String
                    else{
                        
                        return}
                    
                    let unitNum = address["unit_number"] as? String
                    
                    let orderAddress = Address(postalCode: postalCode, streetAddress: street, unitNumber: unitNum, city: city, adminArea: area, country: country)
                    
                    let order = Order(orderID: doc.documentID, timestamp: timestamp, products: [], status: status, intents: intents, shippingIntent: shippingIntent, shippingCost: shippingCost, subtotal: 0, tax: 0, totalCost: 0, address: orderAddress, trackingNumber: trackingNumber)
                    
                    localLoaded.append(order)
                    doc.reference.collection("Purchases").getDocuments(completion: { pSnaps, error in
                        if let err = error{
                            print(err.localizedDescription)
                        }
                        else{
                            guard let pDocs = pSnaps?.documents, !pDocs.isEmpty
                                else{
                                    docCount -= 1
                                    self.addOrderRows(localLoaded: localLoaded)
                                return}
                            for pDoc in pDocs{
                                
                                guard
                                    let productID = pDoc["productID"] as? String,
                                    let quantity = pDoc["quantity"] as? Int,
                                    let size = pDoc["size"] as? String
                                else{
                                    docCount -= 1
                                    continue}
                                let status = pDoc["status"] as? String
                                let price = (pDoc["amount"] as? Double ?? 0) / 100

                                self.getPostBackgroundInfo(postID: productID, completed: { product in
                                    
                                    product?.price = price / Double(quantity)
                                    
                                    subtotal += product?.price ?? 0
                                    
                                    let orderProduct = ProductInCart(product: product, size: size, quantity: quantity, isDeleted: status == "cancelled-print", timestamp: timestamp, timestampDiff: nil, saleID: pDoc.documentID, inBank: nil)
                                    
                                    order.products.append(orderProduct)
                                    if order.products.count == pDocs.count{
                                        order.products.sort(by: {$0.product.productID > $1.product.productID})
                                        order.subtotal = subtotal
                                        order.tax = tax * subtotal
                                        order.totalCost = (order.tax ?? 0.0) + (order.subtotal ?? 0.0) + (order.shippingCost ?? 0.0)
                                        downloaded += 1
                                    }
                                    if downloaded == docCount{
                                        self.addOrderRows(localLoaded: localLoaded)
                                        completed()
                                    }
                                })
                            }
                        }
                    })
                }
            }
        })
    }
    
    func addOrderRows(localLoaded: [Order]){
        for loaded in localLoaded{
            self.orders.append(loaded)
            if self.orders.count == 1{
                self.ordersTableView.reloadData()
            }
            else{
                self.ordersTableView.performBatchUpdates({
                    self.ordersTableView.insertSections(IndexSet(integer: self.orders.count - 1), with: .none)
                }, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showCenterBtn()
        selectedComment = nil
        
        if self.navigationController?.tabBarItem.badgeColor != nil{
            if !isLoadingNotifs{
                downloadNotifs {
                    
                }
            }
        }
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow{
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        if let selectedIndexPathForOrder = ordersTableView.indexPathForSelectedRow{
            ordersTableView.deselectRow(at: selectedIndexPathForOrder, animated: true)
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView{
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath) as? NotificationCell
            let notif = notifications[indexPath.row]
            cell?.vc = nil
            cell?.vc = self
            cell?.notifLbl.text = nil
            cell?.notifPic.image = nil
            cell?.notifPic.backgroundColor = .secondarySystemBackground
            cell?.notifPic.clipsToBounds = true
            cell?.nameBtn.titleLabel?.text = nil
            cell?.nameBtn.setTitle(nil, for: .normal)
            cell?.notif = nil
            cell?.timestampLbl.text = nil
            cell?.removedNotifView.isHidden = true
            cell?.isUserInteractionEnabled = false
            cell?.notifPic.alpha = 1.0
            cell?.dpBtn.superview?.isHidden = true
            cell?.notif = notif
            self.tableView.checkNotifTimes(notif: notif, timestampLbl: cell?.timestampLbl)

            guard !notif.deleted else{
                cell?.removedNotifView.isHidden = false
                return cell!
            }
            
            isMentionBreak:
            if notif.username == nil{
                
                downloadUserInfo(uid: notif.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: { userUID, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postCount, followerCount, followingCount  in
                    
                    if username == nil{
                        for sameNotif in self.notifications.filter({$0.uid == notif.uid}){
                            sameNotif.deleted = true
                            guard let index = self.notifications.firstIndex(where: {$0.notifID == sameNotif.notifID}) else{continue}
                            DispatchQueue.main.async {
                                tableView.performBatchUpdates({
                                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                }, completion: nil)
                            }
                        }
                        return
                    }
                    
                    if notif.userInfo == nil{
                        notif.userInfo = UserInfo()
                    }
                    notif.username = username
                    notif.userInfo.username = username
                    notif.userInfo.fullName = fullName
                    notif.userInfo.dpID = dpUID
                    notif.userInfo.uid = notif.uid
                    notif.userInfo.bio = bio
                    notif.userInfo.postCount = postCount
                    notif.userInfo.followerCount = followerCount
                    notif.userInfo.followingCount = followingCount
                    notif.userInfo.userFollowing = userFollowing
                    notif.userInfo.notifID = notifID
                    notif.userInfo.usersBlocking = usersBlocking
                    notif.userInfo.dp = imgData

                    if let img = imgData, notif.shouldShowDP{
                        DispatchQueue(label: "cache").async {
                            cache.storeImageData(toDisk: img, forKey: dpUID)
                        }
                        cell?.notifPic.image = UIImage(data: img)
                    }
                    else{
                        if notif.notifType != "Mention"{
                            if notif.product == nil{
                                notif.product = Product()
                            }
                            notif.product.userInfo = userInfo
                        }
                    }
                    cell?.isUserInteractionEnabled = true
                    guard let index = self.notifications.firstIndex(where: {$0.notifID == notif.notifID}) else{return}
                    if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                        cell.notif = notif
                    }
                })
            }
            else{
                cell?.isUserInteractionEnabled = true
                cell?.notif = notif
            }
            
            if !notif.shouldShowDP{
                cell?.isDP = false
                if notif.product == nil{
                    notif.product = Product()
                }
                if let color = notif.templateColor{
                    cell?.notifPic.backgroundColor = UIColor(named: color)
                    DispatchQueue(label: "cache").async {
                        if let img = cache.imageFromCache(forKey: "thumbnail_\(notif.picID ?? "")"){
                            DispatchQueue.main.async {
                                guard let index = self.notifications.firstIndex(where: {$0.notifID == notif.notifID}) else{return}
                                if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                    cell.notifPic.image = img
                                    if notif.product?.isAvailable ?? false{
                                        cell.notifPic.alpha = 1.0
                                    }
                                    else{
                                        cell.notifPic.alpha = 0.25
                                    }
                                }
                            }
                        }
                    }
                }
                else{
                    getPostBackgroundInfo(postID: notif.picID, completed: { product in
                        if product == nil{
                            for sameNotif in self.notifications.filter({$0.picID == notif.picID}){
                                sameNotif.deleted = true
                                guard let index = self.notifications.firstIndex(where: {$0.notifID == sameNotif.notifID}) else{continue}
                                tableView.performBatchUpdates({
                                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                }, completion: nil)
                            }
                        }
                        else{
                            notif.product = product
                            guard let templateColor = product?.templateColor else{return}
                            notif.templateColor = templateColor
                            cell?.notifPic.backgroundColor = UIColor(named: templateColor)
                            DispatchQueue(label: "cache").async {
                                if let img = cache.imageFromCache(forKey: "thumbnail_\(notif.picID ?? "")"){
                                    DispatchQueue.main.async {
                                        guard let index = self.notifications.firstIndex(where: {$0.notifID == notif.notifID}) else{return}
                                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                            cell.notifPic.image = img
                                            if notif.product?.isAvailable ?? false{
                                                cell.notifPic.alpha = 1.0
                                            }
                                            else{
                                                cell.notifPic.alpha = 0.25
                                            }
                                        }
                                    }
                                }
                                else{
                                    guard let productUID = product?.userInfo.uid else{return}
                                    DispatchQueue.main.async {
                                        tableView.downloadProductImage(pictureProduct: nil, followingUID: productUID, picID: notif.picID, index: 0, feedVC: nil, friendVC: nil, userVC: nil, fullVC: nil, type: nil, product: nil, completed: { img, imgID in
                                            DispatchQueue(label: "cache").async {
                                                cache.storeImageData(toDisk: img?.pngData(), forKey: "thumbnail_\(imgID ?? "")")
                                            }
                                            guard let index = self.notifications.firstIndex(where: {$0.notifID == notif.notifID}) else{return}
                                            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                                cell.notifPic.image = img
                                                if notif.product?.isAvailable ?? false{
                                                    cell.notifPic.alpha = 1.0
                                                }
                                                else{
                                                    cell.notifPic.alpha = 0.25
                                                }
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    })
                }
            }
            else{
                cell?.isDP = true
                if notif.userInfo == nil{
                    notif.userInfo = UserInfo()
                }
                DispatchQueue(label: "cache").async {
                    if let img = cache.imageFromCache(forKey: notif.userInfo.dpID){
                        DispatchQueue.main.async {
                            guard let index = self.notifications.firstIndex(where: {$0.notifID == notif.notifID}) else{return}
                            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                cell.notifPic.image = img
                            }
                        }
                    }
                }
            }
            return cell!
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchProductCell", for: indexPath) as? SearchProductTableViewCell
            guard orders.indices.contains(indexPath.section), orders[indexPath.section].products.indices.contains(indexPath.row) else{return cell!}
            let savedProduct = orders[indexPath.section].products[indexPath.row]
            guard let product = savedProduct.product, let uid = product.userInfo.uid else{return cell!}
            cell?.productImageView.image = nil
            cell?.priceLbl.text = nil
            cell?.likesLbl.text = nil
            cell?.productNameLbl.text = nil
            cell?.likesView.isHidden = true
            cell?.savedProduct = nil
            cell?.quantityField.isEnabled = false
            cell?.quantityView.isHidden = true
            cell?.productImageView.backgroundColor = .secondarySystemBackground
            cell?.sizingLbl.isHidden = false
            cell?.isDeleted = false
            cell?.productImageView.alpha = 1.0
            
            if !(product.isAvailable){
                cell?.productImageView.alpha = 0.25
            }
            DispatchQueue(label: "explore").async {
                if let dp = cache.imageFromMemoryCache(forKey: "thumbnail_\(product.productID)"){
                    DispatchQueue.main.async {
                        cell?.productImageView.image = dp
                    }
                }
                else{
                    DispatchQueue.main.async {
                        self.getProductImage(productID: product.productID, uid: uid, section: indexPath.section)
                    }
                }
            }
            
            cell?.productImageView.backgroundColor = UIColor(named: product.templateColor)
            cell?.productImageView.backgroundColor = UIColor(named: product.templateColor)
            cell?.productNameLbl.text = product.name
            cell?.savedProduct = savedProduct
            cell?.priceLbl.font = UIFont(name: "NexaW01-Regular", size: cell?.priceLbl.font.pointSize ?? 16)
            cell?.sizingLbl.font = UIFont(name: "NexaW01-Regular", size: cell?.priceLbl.font.pointSize ?? 16)
            if let price = product.price, let qty = savedProduct.quantity{
                cell?.priceLbl.text = "\(qty) x \(price.formatPrice())"
            }
            cell?.sizingLbl.text = "Size: \(savedProduct.size ?? "M")"
            
            return cell!
        }
    }
    
    var downloadingPictures = [String]()
    
    func getProductImage(productID: String, uid: String, section: Int){
        if !self.downloadingPictures.contains(productID){
            self.downloadingPictures.append(productID)
            let refString = "Users/" + uid + "/" + "Products/" + productID + "/" + "thumbnail_\(productID)" + ".png"
            let ref = Storage.storage().reference().child(refString)
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
                                self.downloadingPictures.removeAll(where: {$0 == productID})
                                cache.storeImage(toMemory: image, forKey: "thumbnail_\(productID)")
                                for index in self.orders[section].products.indices{
                                    if self.orders[section].products[index].product.productID == productID{
                                        self.ordersTableView.performBatchUpdates({
                                            self.ordersTableView.reloadRows(at: [IndexPath(row: index, section: section)], with: .none)
                                        }, completion: nil)
                                    }
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        return indexPath
    }
    
    var selectedObject: Any!
    var selectedComment: Comment!
    
    
    @IBAction func toCart(_ sender: UIBarButtonItem) {
        navigationController?.segueToCart()
    }
    
    @IBAction func toSales(_ sender: UIBarButtonItem) {
        navigationController?.segueToSales()
        
        
 
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.tableView{
            let notif = notifications[indexPath.row]
            if notif.notifType == "Report"{
                if notif.notifType == "Report:Post"{
                    selectedObject = notif.product
                    performSegue(withIdentifier: "toReport", sender: nil)
                }
                else{
                    selectedObject = notif.userInfo
                    performSegue(withIdentifier: "toReport", sender: nil)
                }
            }
            else if notif.shouldShowDP{
                selectedObject = notif.userInfo
                performSegue(withIdentifier: "toFriend", sender: nil)
            }
            else{
                selectedObject = notif.product
                
                if notif.notifType == "Mention" || notif.notifType == "Comment"{
                    selectedComment = Comment(timestamp: notif.timestamp, message: notif.commentMessage, commentID: notif.commentID, userInfo: UserInfo(uid: notif.uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil))
                }
                performSegue(withIdentifier: "toFull", sender: nil)
            }
        }
        else{
            guard orders.indices.contains(indexPath.section), orders[indexPath.section].products.indices.contains(indexPath.row) else{return}
            let orderProduct = orders[indexPath.section].products[indexPath.row]
            selectedObject = orderProduct.product

            performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == self.tableView{
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == self.tableView{
            if (editingStyle == .delete) {
                deleteNotif(indexPath: indexPath)
            }
        }
    }
    
    func deleteNotif(indexPath: IndexPath){
        
        guard let uid = userInfo.uid else{return}
        guard let notifID = notifications[indexPath.row].notifID else{return}
        notifications.removeAll(where: {$0.notifID == notifID})
        
        DispatchQueue.main.async {
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }, completion: { finished in
                if finished{
                    Firestore.firestore().collection("Users/\(uid)/Notifications").document(notifID).delete(completion: { error in
                        if let err = error{
                            print(err.localizedDescription)
                        }
                    })
                }
            })
        }
    }
    
    

  
    
    
    
    
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: "NotifCell")
        ordersTableView.register(UINib(nibName: "SearchProductTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchProductCell")

        view.addSubview(ordersTableView)
        ordersTableView.isHidden = true
        

        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refresher)
        
        let orderRefresher = BouncingTitleRefreshControl(title: "thred")
        orderRefresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        ordersTableView.addSubview(orderRefresher)
        
        tableView.adjustForCenterBtn(footerColor: .systemBackground, offset: nil, vc: self)
        ordersTableView.adjustForCenterBtn(footerColor: .systemBackground, offset: nil, vc: self)
     
        segmentedControl.setTitleFont(UIFont(name: "NexaW01-Heavy", size: 14)!)
        segmentedControl.setTitleColor(.white)
        segmentedControl.selectedSegmentTintColor = UIColor(named: "LoadingColor")

        
        switchSegment(segmentedControl)
        // Do any additional setup after loading the view.
    }
    
    
    
    @IBAction func switchSegment(_ sender: UISegmentedControl){
        if sender.selectedSegmentIndex == 0{
            ordersTableView.isHidden = true
            tableView.isHidden = false
            if notifications.isEmpty{
                self.refresh(nil)
            }
        }
        else{
            tableView.isHidden = true
            ordersTableView.isHidden = false
            if orders.isEmpty{
                self.refresh(nil)
            }
        }
    }

    override func viewDidLayoutSubviews() {

    }
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl?){
               
        guard checkInternetConnection() else{
            sender?.endRefreshing()
            return
        }
        if segmentedControl.selectedSegmentIndex == 0{
            if !isLoadingNotifs{
                isLoadingNotifs = true
                sender?.animateRefresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.downloadNotifs {
                        sender?.endRefreshing()
                    }
                }
            }
            else{
                sender?.endRefreshing()
            }
        }
        else{
            if !isLoadingOrders{
                isLoadingOrders = true
                sender?.animateRefresh()
                if orders.isEmpty{
                    ordersTableView.reloadData()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.downloadOrders {
                        if self.orders.isEmpty{
                            self.ordersTableView.reloadData()
                        }
                        sender?.endRefreshing()
                    }
                }
            }
            else{
                sender?.endRefreshing()
            }
        }
    }
    
    func downloadNotifs(completed: @escaping () -> ()){
        if !isLoadingNotifs{
            isLoadingNotifs = true
        }
        getNotifications {
            self.isLoadingNotifs = false
            self.tableView.reloadData()
            completed()
        }
    }
    
    func downloadOrders(completed: @escaping () -> ()){
        if !isLoadingOrders{
            isLoadingOrders = true
        }
        orders.removeAll()
        lastDoc = nil
        getOrders {
            self.isLoadingOrders = false
            completed()
        }
    }
    
    
    func getNotifications(completed: @escaping () -> ()){
        
        guard let uid = userInfo.uid else{return}
        checkAuthStatus {
            self.refreshLists(userUID: uid){
                let query = Firestore.firestore().collection("Users/\(uid)/Notifications").order(by: "Timestamp", descending: true).limit(to: 30)
                query.getDocuments(completion: { snaps, error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        completed()
                    }else{
                        if let docs = snaps?.documents, !docs.isEmpty{
                            self.notifications.removeAll()
                            for doc in docs{
                                guard let uid = doc["UID"] as? String else{
                                    continue}
                                if userInfo.usersBlocking.contains(uid){
                                    continue
                                }
                                let timestamp = (doc["Timestamp"] as? Timestamp)?.dateValue()
                                var type = doc["Type"] as? String
                                
                                let picID = doc["Product_ID"] as? String
                                if type == "Report"{
                                    if picID != nil{
                                        type?.append(":Post")
                                    }
                                    else{
                                        type?.append(":Account")
                                    }
                                }
                                let commentMessage = doc["Comment_Message"] as? String
                                let commentID = doc["Comment_ID"] as? String

                                self.notifications.append(UserNotification(notifID: doc.documentID, uid: uid, notifType: type, timestamp: timestamp, username: nil, picID: picID, shouldShowDP: type == "Follow" || type == "Bio_Mention" || (type == "Report" && picID != nil), templateColor: nil, timestampDiff: nil, commentMessage: commentMessage, commentID: commentID, deleted: false))
                            }
                            completed()
                        }
                        else{
                            completed()
                        }
                    }
                })
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 85
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == ordersTableView{
            return 85
        }
        return UITableView.automaticDimension
    }
    
    lazy var headerView: UIView? = {
        
        return loadNotifHeaderFromNib()
    }()
    
    lazy var ordersHeaderView: UIView? = {
        
        return loadOrdersHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    lazy var orderLoadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    @objc func segueToFullOrder(_ sender: UIButton){
        if let header = sender.superview?.superview{
            let section = header.tag
            fullOrder = orders[section]
            self.performSegue(withIdentifier: "toOrder", sender: nil)
        }
    }
    
    func orderNumberView(section: Int) -> UIView{
        
        let aview = UIView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
        let sView = UIStackView(frame: CGRect(x: 10, y: 5, width: aview.frame.width - 10, height: aview.frame.height - 10))
        sView.axis = .horizontal
        aview.tag = section
        let label = UIButton.init(frame: sView.frame)
        label.titleLabel?.numberOfLines = 1
        label.titleLabel?.adjustsFontSizeToFitWidth = true
        label.titleLabel?.lineBreakMode = .byClipping
        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: label.frame.height / 3, height: label.frame.height))
        imageView.image = UIImage(named: "arrowBtn")
        imageView.contentMode = .scaleAspectFit
        let cancelBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: label.frame.height, height: label.frame.height))
        cancelBtn.addTarget(self, action: #selector(segueToFullOrder(_:)), for: .touchUpInside)
        label.addTarget(self, action: #selector(segueToFullOrder(_:)), for: .touchUpInside)
        guard let font = UIFont(name: "NexaW01-Heavy", size: 12) else{return aview}
        var color: UIColor!
        var string: String!
        
        switch orders[section].status.lowercased(){
        case "confirmed":
            color = UIColor.systemYellow
            string = "CONFIRMED"
        case "cancelled":
            color = UIColor.red
            string = "CANCELLED"
        case "cancelled-print":
            color = UIColor.red
            string = "CANCELLED"
        case "completed":
            color = UIColor(named: "LoadingColor")
            string = "COMPLETED"
        case "shipped":
            color = UIColor(named: "LoadingColor")
            string = "SHIPPED"
        default:
            color = UIColor.red
            string = "ERROR"
            break
        }
        
        imageView.tintColor = color
        
        let attributes = [
            NSAttributedString.Key.font : font,
            NSAttributedString.Key.foregroundColor : color!.withAlphaComponent(0.75)
        ] as [NSAttributedString.Key : Any]
        
        let btnTitle = NSAttributedString(string: string, attributes: attributes)
        

        cancelBtn.setAttributedTitle(btnTitle, for: .normal)
        label.contentHorizontalAlignment = .left
        label.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);

        
        label.tag = section
        sView.addArrangedSubview(label)
        sView.addArrangedSubview(cancelBtn)
        sView.addArrangedSubview(imageView)
        aview.addSubview(sView)
        print(section)

        guard let title = self.orders[section].orderID else{return aview}
        unboldTitle(orderNumber: title, label: label)
        aview.addBackgroundBlur(blurEffect: UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial))
        return aview
    }
    
    func unboldTitle(orderNumber: String, label: UIButton){
        let linkWords = "Order #:"
        label.titleLabel?.text = nil
        label.setTitle(nil, for: .normal)
        let guideLineText = "Order #: \(orderNumber)"
        
        label.titleLabel?
            .text = guideLineText
        label.setTitle(guideLineText, for: .normal)
        
        let attrString = NSMutableAttributedString()
        if let text = label.titleLabel?.attributedText{
            attrString.setAttributedString(text)
        }
        
        let nsText = NSString(string: guideLineText)
        let matchRange:NSRange = nsText.range(of: linkWords)
        let orderRange:NSRange = nsText.range(of: orderNumber)

        
        guard let font = UIFont(name: "NexaW01-Heavy", size: 12) else{return}
        
        let attributes = [
            NSAttributedString.Key.font : font,
            NSAttributedString.Key.foregroundColor : UIColor.tertiaryLabel
        ] as [NSAttributedString.Key : Any]
        
        guard let orderFont = UIFont(name: "NexaW01-Heavy", size: 12) else{return}
        
        let orderAttributes = [
            NSAttributedString.Key.font : orderFont,
            NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel
        ] as [NSAttributedString.Key : Any]
        
        attrString.addAttributes(attributes, range: matchRange)
        attrString.addAttributes(orderAttributes, range: orderRange)

        label.titleLabel?.attributedText = attrString
        label.setAttributedTitle(attrString, for: .normal)

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == ordersTableView{
            if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) / 2{
                print("fromScroll")
                if !isLoadingOrders, canLoadMore{
                    isLoadingOrders = true
                    getOrders {
                        self.isLoadingOrders = false
                    }
                }
            }
        }
    }
    
    var canLoadMore = false
    
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == self.tableView{
            if notifications.isEmpty{
                if isLoadingNotifs{
                    loadingView?.spinner.animate()
                    return loadingView
                }
                else{
                    return headerView
                }
            }
        }
        else{
            if orders.isEmpty{
                if isLoadingOrders{
                    orderLoadingView?.spinner.animate()
                    return orderLoadingView
                }
                else{
                    return ordersHeaderView
                }
            }
            else{
                return orderNumberView(section: section)
            }
        }
        return nil
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if tableView == self.tableView{
            if notifications.isEmpty{
                return 100
            }
            return 0
        }
        else{
            if orders.isEmpty{
                return 140
            }
            return 30
        }
    }

    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let productVC = segue.destination as? FullProductVC{
            guard let product = selectedObject as? Product else{return}
            productVC.fullProduct = product
            productVC.selectedComment = selectedComment
        }
        if let userVC = segue.destination as? FriendVC{
            guard let user = selectedObject as? UserInfo else{return}
            userVC.friendInfo = user
        }
        if let orderVC = segue.destination as? FullOrderVC{
            guard let order = fullOrder else{return}
            orderVC.order = order
        }
    }
    

}

extension UINavigationController{
    
    func pushViewControllerFromLeft(viewController: UIViewController){
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        pushViewController(viewController, animated: false)
    }
    
    func popViewControllerFromRight(viewController: UIViewController){
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        popViewController(animated: false)
    }
}

extension UIViewController{
    func getPostBackgroundInfo(postID: String, completed: @escaping (Product?) -> ()){
        guard let userUID = userInfo.uid else{return}
        Firestore.firestore().collectionGroup("Products").whereField("Product_ID", isEqualTo: postID).getDocuments(completion: { snaps, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                guard let snap = snaps?.documents.first else{
                    completed(nil)
                    return}
                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                guard let uid = snap["UID"] as? String else{
                    return}
                let isAvailable = snap["Available"] as? Bool
                let description = snap["Description"] as? String
                let name = snap["Name"] as? String
                let blurred = snap["Blurred"] as? Bool
                let templateColor = snap["Template_Color"] as? String
                let likes = snap["Likes"] as? Int
                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                let comments = ((snap["Comments"]) as? Int) ?? 0
                let isPublic = snap["Public"] as? Bool ?? true
                let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: 0, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: isAvailable, isPublic: isPublic)
                
                Firestore.firestore().collection("Users").document(uid).collection("Products").document(product.productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userUID).getDocuments(completion: { snapLikes, error in
                
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
                    completed(product)
                    return
                })
            }
        })
    }
}

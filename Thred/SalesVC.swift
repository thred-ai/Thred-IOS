//
//  SalesVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-16.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import WebKit
import ColorCompatibility
import PopupDialog
import StoreKit
import SwiftKeychainWrapper


class SalesVC: UIViewController, WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var payoutBtn: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    var selectedObject: Any!
    var refresher: BouncingTitleRefreshControl!
    var salesProducts = [ProductInCart]()
    
    var webView: WKWebView!
    var viewSpinner: MapSpinnerView!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var webViewBack: UIView = {
        let back = UIView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height))
        back.backgroundColor = .systemBackground
        let stackView = UIStackView(frame: back.bounds)
        stackView.axis = .vertical
        stackView.spacing = 10
        
        let viewBehind = UIView(frame: CGRect(x: 0, y: 0, width: back.frame.width, height: view.frame.height))
        viewSpinner = MapSpinnerView.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        viewSpinner.center = viewBehind.center
        viewBehind.addSubview(viewSpinner)
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: back.frame.width, height: 30))
        button.backgroundColor = .systemBackground
        button.setImage(UIImage.init(nameOrSystemName: "chevron.down", systemPointSize: 22, iconSize: 9), for: .normal)
        button.tintColor = UIColor(named: "LoadingColor")
        button.addTarget(self, action: #selector(hideStripeView(_:)), for: .touchUpInside)
        webView = WKWebView.init(frame: CGRect(x: 0, y: 0, width: back.frame.width, height: view.frame.height))
        webView.navigationDelegate = self
        viewBehind.addSubview(webView)
        back.addSubview(stackView)
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(viewBehind)
        return back
    }()
    
    @objc func hideStripeView(_ sender: UIButton?){
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.webViewBack.frame.origin.y = self.view.frame.height
            })
        }
    }
    
    var lastDoc: DocumentSnapshot?
    
    func getSales(completed: @escaping (Bool) -> ()){
        
        var query: Query?
        guard let uid = pUserInfo.uid else{ completed(false); return}
        if let doc = lastDoc{
            query = Firestore.firestore().collectionGroup("Purchases").whereField("merchant_uid", isEqualTo: uid).whereField("status", isEqualTo: "confirmed").order(by: "timestamp", descending: true).start(afterDocument: doc).limit(to: 15)
        }
        else{
            query = Firestore.firestore().collectionGroup("Purchases").whereField("merchant_uid", isEqualTo: uid).whereField("status", isEqualTo: "confirmed").order(by: "timestamp", descending: true).limit(to: 15)
        }
        
        query?.getDocuments(completion: { snaps, error in
            if let err = error{
                print(err.localizedDescription)
                completed(false)
            }
            else{
                guard let docs = snaps?.documents, !docs.isEmpty else{
                    completed(false)
                    return}
                self.lastDoc = docs.last
                for doc in docs{
                    guard
                        let customer_uid = doc["customer_uid"] as? String,
                        let product_id = doc["productID"] as? String,
                        let size = doc["size"] as? String,
                        let quantity = doc["quantity"] as? Int,
                        let timestamp = (doc["timestamp"] as? Timestamp)?.dateValue()
                    else{ continue }
                    let price = (doc["amount"] as? Double ?? 0) / 100
                    let toBank = doc["toBank"] as? Bool ?? false
                    let moneyMade = (doc["moneyToMerchant"] as? Double ?? 0) / 100
                    let currency = doc["currency"] as? String ?? "CAD"
                    let productUserInfo = UserInfo(uid: customer_uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
 
                    let product = Product(userInfo: productUserInfo, picID: nil, description: nil, productID: product_id, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: price / Double(quantity), name: nil, templateColor: nil, likes: nil, liked: pUserInfo.userLiked.contains(doc.documentID), designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil, displaySide: nil, supportedSides: [])
                    let saleProduct = ProductInCart(product: product, size: size, quantity: quantity, isDeleted: false, timestamp: timestamp, timestampDiff: nil, saleID: doc.documentID, inBank: toBank, moneyMade: moneyMade)
                    saleProduct.currency = currency
                    self.salesProducts.append(saleProduct)
                   
                    self.tableView.performBatchUpdates({
                        self.tableView.insertRows(at: [IndexPath(row: self.salesProducts.count - 1, section: 0)], with: .fade)
                    }, completion: { finished in
                        if finished{
                            if doc == docs.last{
                                self.checkRate()
                            }
                        }
                    })
                }
                completed(true)
            }
        })
    }
    
    
    func showBankMessage(product: ProductInCart, completed: @escaping () -> ()){
        
        var title = String()
        var titleColor = UIColor()
        let fullname = pUserInfo.fullName ?? "<null>"
        var moneyMade = product.moneyMade?.formatPrice(addCurrency: product.currency?.shortenCurrency() ?? "") ?? "CA$0.00"

        switch product.inBank{
        case true:
            titleColor = UIColor.systemGreen
            let price = product.product.price ?? 20.00            
            if moneyMade == "CA$0.00"{
                var minPrice = 20.00
                
                if product.product.productType == "MASK"{
                    minPrice = 15.00
                }
                moneyMade = (((price - minPrice) * Double(product.quantity)) * 0.90).formatPrice(addCurrency: product.currency?.shortenCurrency() ?? "")
                print(price)
                print(minPrice)
                print(moneyMade)
            }
            title = "COMMISSION EARNED"
        default:
            titleColor = UIColor.red
            moneyMade = "$0.00"
            title = "NO COMMISSION EARNED"
        }
        let description = "\(fullname) earned \(moneyMade) from this sale."

        let yesBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        
        showPopUp(title: title, message: description, image: nil, buttons: [yesBtn], titleColor: titleColor, blurBack: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return salesProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath) as? NotificationCell
        let sale = salesProducts[indexPath.row]
        cell?.vc = nil
        cell?.vc = self
        cell?.notifLbl.text = nil
        cell?.notifPic.image = nil
        cell?.notifPic.backgroundColor = .secondarySystemBackground
        cell?.notifPic.clipsToBounds = true
        cell?.nameBtn.titleLabel?.text = nil
        cell?.nameBtn.setTitle(nil, for: .normal)
        cell?.notif = nil
        cell?.nameBtn.titleLabel?.attributedText = nil
        cell?.nameBtn.setAttributedTitle(nil, for: .normal)
        cell?.timestampLbl.text = nil
        cell?.removedNotifView.isHidden = true
        cell?.isUserInteractionEnabled = false
        cell?.notifPic.alpha = 1.0
        cell?.dpBtn.imageView?.image = nil
        cell?.dpBtn.setImage(nil, for: .normal)
        
        if sale.inBank ?? false, let data = pUserInfo.dp, let image = UIImage(data: data){
            cell?.dpBtn.imageView?.image = image
            cell?.dpBtn.setImage(image, for: .normal)
        }
        else{
            cell?.dpBtn.imageView?.image = UIImage(named: "thred.logo.light")
            cell?.dpBtn.setImage(UIImage(named: "thred.logo.light"), for: .normal)
        }
        
        cell?.salesProduct = sale
        tableView.checkSalesTimes(sale: sale, timestampLbl: cell?.timestampLbl)

        cell?.isDP = false

        if sale.product.userInfo.username == nil{
            
            downloadUserInfo(uid: sale.product.userInfo.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: { userUID, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postNotifs, postCount, followerCount, followingCount, verified in
                
                if username == nil{
                    for sameNotif in self.salesProducts.filter({$0.product.userInfo.uid == sale.product.userInfo.uid}){
                        //sameNotif.deleted = true
                        guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sameNotif.saleID}) else{continue}
                        DispatchQueue.main.async {
                            tableView.performBatchUpdates({
                                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }, completion: nil)
                        }
                    }
                    return
                }
                
                sale.product.userInfo.username = username
                sale.product.userInfo.username = username
                sale.product.userInfo.fullName = fullName
                sale.product.userInfo.dpID = dpUID
                sale.product.userInfo.uid = userUID
                sale.product.userInfo.bio = bio
                sale.product.userInfo.postCount = postCount
                sale.product.userInfo.followerCount = followerCount
                sale.product.userInfo.followingCount = followingCount
                sale.product.userInfo.userFollowing = userFollowing
                sale.product.userInfo.notifID = notifID
                sale.product.userInfo.usersBlocking = usersBlocking
                sale.product.userInfo.dp = imgData
                sale.product.userInfo.verified = verified ?? false

                cell?.isUserInteractionEnabled = true
                guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sale.saleID}) else{return}
                if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                    cell.salesProduct = sale
                }
            })
        }
        else{
            cell?.isUserInteractionEnabled = true
            cell?.salesProduct = sale
        }
                
        
        if let color = sale.product.templateColor{
            
            let colorInfo = all.tees.first(where: {$0.productCode == sale.product?.productType})?.colors.first(where: {$0.code == color})

            cell?.notifPic.backgroundColor = colorInfo?.getColor()
            DispatchQueue(label: "cache").async {
                var prefix = ""
                if sale.product?.displaySide == "back" || sale.product?.displaySide == "Back"{
                    prefix = "BACK_"
                }
                if let img = cache.imageFromCache(forKey: "thumbnail_\(prefix)\(sale.product.productID)"){
                    DispatchQueue.main.async {
                        guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sale.saleID}) else{return}
                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                            cell.notifPic.image = img
                            if sale.product?.isAvailable ?? false{
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
            getPostBackgroundInfo(postID: sale.product.productID, completed: { product in
                    if product == nil{
                        for sameNotif in self.salesProducts.filter({$0.product.productID == sale.product.productID}){
                            guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sameNotif.saleID}) else{continue}
                            tableView.performBatchUpdates({
                                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }, completion: nil)
                        }
                    }
                    else{
                        product?.price = sale.product.price
                        sale.product = product
                        guard let templateColor = product?.templateColor else{return}
                        sale.product.templateColor = templateColor
                        let colorInfo = all.tees.first(where: {$0.productCode == sale.product?.productType})?.colors.first(where: {$0.code == templateColor})
                        cell?.notifPic.backgroundColor = colorInfo?.getColor()
                        DispatchQueue(label: "cache").async {
                            var prefix = ""
                            if product?.displaySide == "back" || product?.displaySide == "Back"{
                                prefix = "BACK_"
                            }
                            if let img = cache.imageFromCache(forKey: "thumbnail_\(prefix)\(sale.product.picID ?? "")"){
                                DispatchQueue.main.async {
                                    guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sale.saleID}) else{return}
                                    if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                        cell.notifPic.image = img
                                        if product?.isAvailable ?? false{
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
                                    var prefix = ""
                                    if product?.displaySide == "back" || product?.displaySide == "Back"{
                                        prefix = "BACK_"
                                    }
                                    tableView.downloadProductImage(pictureProduct: nil, followingUID: productUID, picID: sale.product.productID, index: 0, feedVC: nil, friendVC: nil, userVC: nil, fullVC: nil, type: nil, product: product, completed: { img, imgID in
                                        DispatchQueue(label: "cache").async {
                                            cache.storeImageData(toDisk: img?.pngData(), forKey: "thumbnail_\(prefix)\(sale.product.productID)")
                                        }
                                        sale.product.picID = imgID
                                        guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sale.saleID}) else{return}
                                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                            cell.notifPic.image = img
                                            if product?.isAvailable ?? false{
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
        return cell!
    }
    
    @IBAction func toPricingGuide(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toCommissionCalc", sender: nil)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sale = salesProducts[indexPath.row]
        
        selectedObject = sale.product
        performSegue(withIdentifier: "toFull", sender: nil)
    }
    
    lazy var headerView: UIView? = {
        
        return loadSalesHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if salesProducts.isEmpty{
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if salesProducts.isEmpty{
            return 140
        }
        return 0
    }
    
    @IBAction func payoutBalance(_ sender: UIButton) {
        progressView.setProgress(0.6, animated: true)
        showStripeView {
            let data = ["uid" : pUserInfo.uid]
            Functions.functions().httpsCallable("getExpressLoginLink").call(data, completion: { result, error in
                if let err = error{
                    print(err.localizedDescription)
                    self.progressView.setProgress(0.0, animated: true)
                }
                else{
                    self.progressView.setProgress(1.0, animated: true)
                    self.progressView.setProgress(0.0, animated: false)
                    
                    guard let data = (result?.data as? [String : Any]) else{return}
                    guard let urlString = (data["url"] as? String), let url = URL(string: urlString) else{return}
                    self.loadWebView(url: url)
                }
            })
        }
    }
    
    var isLoading = false
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) / 2{
            print("fromScroll")
            
            if !self.isLoading, canLoadMore{
                self.isLoading = true
                self.getSales(completed: { finished in
                    self.isLoading = false
                    if self.tableView.refreshControl?.isRefreshing ?? true{
                        self.tableView.refreshControl?.endRefreshing()
                    }
                })
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

    
    
    func showStripeView(completed: @escaping () -> ()){
        webView.isHidden = true
        viewSpinner.animate()
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.webViewBack.frame.origin.y = self.view.safeAreaInsets.top
            })
            completed()
        }
    }
    
    func loadWebView(url: URL){
        let request = URLRequest(url: url)
        self.webView.load(request)
        DispatchQueue.main.async {
            self.webView.isHidden = false
        }
    }
    
    func showWebView(){
        
    }
    
    
    @IBAction func popToViewController(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var salesLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        payoutBtn.layer.cornerRadius = payoutBtn.frame.height / 8
        payoutBtn.clipsToBounds = true
        tableView.register(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: "NotifCell")
        tableView.delegate = self
        tableView.dataSource = self
        refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refresher)
        salesLbl.text = " "
        tableView.allowsSelection = true
        self.hidesBottomBarWhenPushed = true
        // Do any additional setup after loading the view.
        loadSalesCount()
        
        refresh(nil)
        payoutBtn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        payoutBtn.isEnabled = false
        if UserDefaults.standard.string(forKey: "BANK_INSTITUTION") != nil,
            UserDefaults.standard.string(forKey: "BANK_LAST_4") != nil{
            payoutBtn.isEnabled = true
        }
    }
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl?){
                
        guard checkInternetConnection() else{
            sender?.endRefreshing()
            return
        }
        
        if !isLoading{
            isLoading = true
            sender?.animateRefresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.lastDoc = nil
                self.loadSalesCount()
                if !self.salesProducts.isEmpty{
                    self.salesProducts.removeAll()
                    self.tableView.reloadData()
                }
                self.getSales(completed: {_ in
                    self.isLoading = false
                    if self.salesProducts.isEmpty{
                        self.tableView.reloadData()
                    }
                    sender?.endRefreshing()
                })
            }
        }
        else{
            sender?.endRefreshing()
        }
    }
    
    func checkRate(){
        if salesProducts.count >= 1{
            if !(KeychainWrapper.standard.bool(forKey: "Prompted") ?? false){
                KeychainWrapper.standard.set(true, forKey: "Prompted")
                SKStoreReviewController.requestReview()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        if !view.subviews.contains(webViewBack){
            view.addSubview(webViewBack)
        }
    }
    
    func loadSalesCount(){
        
        guard let uid = pUserInfo.uid else{return}
        
        Firestore.firestore().collection("Users/\(uid)/Payment_Info").document("Seller_Stats").getDocument(completion: { snap, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                var salesNum = (snap?["Sales"] as? Int) ?? 0
                if salesNum < 0{
                    salesNum = 0
                    snap?.reference.updateData(["Sales" : 0])
                }
                self.salesLbl.text = "\(salesNum)"
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        hideCenterBtn()
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else{return}
        tableView.deselectRow(at: selectedIndexPath, animated: true)
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let productVC = segue.destination as? FullProductVC{
            guard let product = selectedObject as? Product else{return}
            productVC.fullProduct = product
        }
        if let userVC = segue.destination as? FriendVC{
            guard let user = selectedObject as? UserInfo else{return}
            userVC.friendInfo = user
        }
    }
    

}

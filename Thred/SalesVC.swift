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
        back.backgroundColor = ColorCompatibility.systemBackground
        let stackView = UIStackView(frame: back.bounds)
        stackView.axis = .vertical
        stackView.spacing = 10
        
        let viewBehind = UIView(frame: CGRect(x: 0, y: 0, width: back.frame.width, height: view.frame.height))
        viewSpinner = MapSpinnerView.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        viewSpinner.center = viewBehind.center
        viewBehind.addSubview(viewSpinner)
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: back.frame.width, height: 30))
        button.backgroundColor = ColorCompatibility.systemBackground
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
        guard let uid = userInfo.uid else{ completed(false); return}
        if let doc = lastDoc{
            query = Firestore.firestore().collectionGroup("Purchases").whereField("merchant_uid", isEqualTo: uid).order(by: "timestamp", descending: true).start(afterDocument: doc).limit(to: 15)
        }
        else{
            query = Firestore.firestore().collectionGroup("Purchases").whereField("merchant_uid", isEqualTo: uid).order(by: "timestamp", descending: true).limit(to: 15)
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
                        let timestamp = (doc["timestamp"] as? Timestamp)?.dateValue(),
                        let price = doc["amount"] as? Double
                    else{ continue }
                    
                    let productUserInfo = UserInfo(uid: customer_uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil)
                    
                    let product = Product(userInfo: productUserInfo, picID: nil, description: nil, productID: product_id, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: price / Double(quantity), name: nil, templateColor: nil, likes: nil, liked: userInfo.userLiked.contains(doc.documentID), designImage: nil, comments: nil, link: nil)
                    
                    self.salesProducts.append(ProductInCart(product: product, size: size, quantity: quantity, isDeleted: false, timestamp: timestamp, timestampDiff: nil, saleID: doc.documentID))
                   
                    self.tableView.performBatchUpdates({
                        self.tableView.insertRows(at: [IndexPath(row: self.salesProducts.count - 1, section: 0)], with: .none)
                    }, completion: { finished in
                        if finished{
                            if doc == docs.last{
                                completed(true)
                            }
                        }
                    })
                }
            }
        })
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
        cell?.notifPic.backgroundColor = ColorCompatibility.secondarySystemBackground
        cell?.notifPic.clipsToBounds = true
        cell?.nameBtn.titleLabel?.text = nil
        cell?.nameBtn.setTitle(nil, for: .normal)
        cell?.notif = nil
        cell?.timestampLbl.text = nil
        cell?.removedNotifView.isHidden = true
        cell?.isUserInteractionEnabled = false
        cell?.salesProduct = sale
        self.tableView.checkSalesTimes(sale: sale, timestampLbl: cell?.timestampLbl)

        cell?.isDP = false

        if sale.product.userInfo.username == nil{
            
            downloadUserInfo(uid: sale.product.userInfo.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: { userUID, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postCount, followerCount, followingCount, profileLink  in
                
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
                sale.product.userInfo.profileLink = profileLink

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
            cell?.notifPic.backgroundColor = UIColor(named: color)
            DispatchQueue(label: "cache").async {
                if let img = cache.imageFromCache(forKey: "thumbnail_\(sale.product.picID ?? "")"){
                    DispatchQueue.main.async {
                        guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sale.saleID}) else{return}
                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                            cell.notifPic.image = img
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
                        sale.product = product
                        guard let templateColor = product?.templateColor else{return}
                        sale.product.templateColor = templateColor
                        cell?.notifPic.backgroundColor = UIColor(named: templateColor)
                        DispatchQueue(label: "cache").async {
                            if let img = cache.imageFromCache(forKey: "thumbnail_\(sale.product.picID ?? "")"){
                                DispatchQueue.main.async {
                                    guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sale.saleID}) else{return}
                                    if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                        cell.notifPic.image = img
                                    }
                                }
                            }
                            else{
                                guard let productUID = product?.userInfo.uid else{return}
                                DispatchQueue.main.async {
                                    tableView.downloadProductImage(pictureProduct: nil, followingUID: productUID, picID: sale.product.productID, index: 0, feedVC: nil, friendVC: nil, userVC: nil, fullVC: nil, type: nil, product: nil, completed: { img, imgID in
                                        DispatchQueue(label: "cache").async {
                                            cache.storeImageData(toDisk: img?.pngData(), forKey: imgID)
                                        }
                                        sale.product.picID = imgID
                                        guard let index = self.salesProducts.firstIndex(where: {$0.saleID == sale.saleID}) else{return}
                                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell{
                                            cell.notifPic.image = img
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
            let data = ["uid" : userInfo.uid]
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
    
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            
            if !self.isLoading{
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
    }
    
    override func viewWillLayoutSubviews() {
        if !view.subviews.contains(webViewBack){
            view.addSubview(webViewBack)
        }
    }
    
    func loadSalesCount(){
        
        guard let uid = userInfo.uid else{return}
        
        Firestore.firestore().collection("Users/\(uid)/Payment_Info").document("Seller_Stats").getDocument(completion: { snap, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                let salesNum = (snap?["Sales"] as? Int) ?? 0
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

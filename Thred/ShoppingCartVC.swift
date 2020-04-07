//
//  ShoppingCartVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-02.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import SDWebImage
import Firebase

class ProductInCart{
    
    var product: Product!
    var size: String!
    var quantity: Int!
    var isDeleted: Bool
    var timestamp: Date!
    
    init(product: Product?, size: String!, quantity: Int!, isDeleted: Bool, timestamp: Date!) {
        self.product = product
        self.size = size
        self.quantity = quantity
        self.isDeleted = isDeleted
        self.timestamp = timestamp
    }
    convenience init() {
        self.init(product: nil, size: nil, quantity: nil, isDeleted: false, timestamp: nil)
    }
}

class ShoppingCartVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var checkoutBtn: UIButton!

    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.delegate = self

        guard let selectedIndexPath = tableView.indexPathForSelectedRow else{return}
        tableView.deselectRow(at: selectedIndexPath, animated: true)
    }
    
    
    
    
    
    
    var downloader: SDWebImageDownloader? = SDWebImageDownloader.init(config: .default)
    var savedProducts = [ProductInCart]()
    var allSavedProducts = [ProductInCart]()
    var refresher: BouncingTitleRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        hideCenterBtn()
        tableView.register(UINib(nibName: "SearchProductTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchProductCell")
        refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        // Do any additional setup after loading the view.
        tableView.addSubview(refresher)
        downloadCart {
        }
    }
    
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if viewController.isKind(of: UITabBarController.self){
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
        else{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }

    
    override func viewDidLayoutSubviews() {
        checkoutBtn.layer.cornerRadius = checkoutBtn.frame.height / 8
        checkoutBtn.clipsToBounds = true
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    lazy var headerView: UIView? = {
        
        return loadCartHeaderFromNib()
    }()
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if allSavedProducts.isEmpty{
            return headerView
        }
        return nil
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if allSavedProducts.isEmpty{
            return 150
        }
        return 0
    }
    
    @IBAction func checkOut(_ sender: UIButton) {
        self.showErrorMessage {
            
        }
    }
    
    var isLoading = false
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
                
        if !isLoading{
            isLoading = true
            sender.animateRefresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.allSavedProducts.removeAll()
                self.savedProducts.removeAll()
                self.downloadCart {
                    self.isLoading = false
                    DispatchQueue.main.async {
                        sender.endRefreshing()
                    }
                }
            }
        }
        
    }
    
    func downloadCart(completed: @escaping () -> ()){
        self.getCartList(completed: { productList in
            self.allSavedProducts = productList
            self.getProducts(isRefreshing: true){
                completed()
            }
        })
    }

    
    var downloadingPictures = [String]()
    var downloadingProfiles = [String]()

    func getProducts(isRefreshing: Bool, completed: @escaping () -> ()){
        
        let productIDs = allSavedProducts.compactMap({$0.product}).compactMap({$0.productID})
        
        
        guard !productIDs.isEmpty else{
            
            completed(); return}
        
        
        for (index, id) in productIDs.enumerated(){
            
            let currentCartProduct = self.allSavedProducts[index]

            if let same = savedProducts.first(where: {$0.product.productID == id && $0.product.timestamp != nil}){
                let product = ProductInCart(product: same.product, size: currentCartProduct.size, quantity: currentCartProduct.quantity, isDeleted: currentCartProduct.isDeleted, timestamp: currentCartProduct.timestamp)
                self.savedProducts.append(product)
                self.tableView.reloadData()
                continue
            }
            
            let query = Firestore.firestore().collectionGroup("Products").whereField("Product_ID", isEqualTo: id).order(by: "Timestamp")
            
            query.getDocuments(completion: { snaps, error in
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                    guard let snap = snaps?.documents.first else{
                        
                        return}
                    
                    let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                    guard let uid = snap["UID"] as? String else{
                        
                        return}
                    
                    let description = snap["Description"] as? String
                    let name = snap["Name"] as? String
                    let blurred = snap["Blurred"] as? Bool
                    let templateColor = snap["Template_Color"] as? String
                    let likes = snap["Likes"] as? Int
                    guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                    let comments = ((snap["Comments"]) as? Int) ?? 0
                    
                    let product = Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: 0, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments)
                    
                    let productInCart = ProductInCart(product: product, size: currentCartProduct.size, quantity: currentCartProduct.quantity, isDeleted: false, timestamp: currentCartProduct.timestamp)
                    self.savedProducts.append(productInCart)
                    self.tableView.reloadData()
                    if !self.downloadingPictures.contains(snap.documentID){
                        self.downloadingPictures.append(snap.documentID)
                        let ref = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + snap.documentID + "/" + "thumbnail_\(snap.documentID)" + ".png")
                        ref.downloadURL(completion: { url, error in
                            if error != nil{
                                print(error?.localizedDescription ?? "")
                            }
                            else{
                                var dub: CGFloat = 0
                                self.downloader?.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                                    dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                                    print("Progress \(dub)")
                                }, completed: { (image, data, error, finished) in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        if let image = image{
                                            self.downloadingPictures.removeAll(where: {$0 == snap.documentID})
                                            cache.storeImage(toMemory: image, forKey: "thumbnail_\(snap.documentID)")
                                            for index in self.savedProducts.indices{
                                                if self.savedProducts[index].product.productID == snap.documentID{
                                                    self.tableView.performBatchUpdates({
                                                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
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
            })
            if id == productIDs.last{
                completed()
            }
        }
    }
    
    
    func getCartList(completed: @escaping ([ProductInCart]) -> ()){
        
        guard let uid = userInfo.uid else{return}

        Firestore.firestore().collection("Users").document(uid).collection("Cart_Info").document("Cart_List").getDocument(completion: { doc, error in
            
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                guard let doc = doc else{return}
                var localLoaded = [ProductInCart]()
                guard let cartList = doc["Cart_List"] as? [[String : Any]] else{
                    
                    
                    return
                }
                
                for product in cartList{
                    let uid = product["UID"] as! String
                    let size = product["Size"] as? String ?? "M"
                    let qty = product["Qty"] as? Int ?? 1
                    let timestamp = (product["Timestamp"] as? Timestamp)?.dateValue()
                    guard let productID = product["Post_ID"] as? String else{return}
                    if userInfo.usersBlocking.contains(uid){
                        continue
                    }
                    let product = Product(uid: uid, picID: productID, description: nil, fullName: nil, username: nil, productID: productID, userImageID: nil, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil)
                    let productInCart = ProductInCart(product: product, size: size, quantity: qty, isDeleted: false, timestamp: timestamp)
                    localLoaded.append(productInCart)
                }
                completed(localLoaded)
            }
        })
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedProducts.count
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        downloader?.invalidateSessionAndCancel(true)
        downloader = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.delegate = self
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchProductCell", for: indexPath) as? SearchProductTableViewCell
        let savedProduct = self.savedProducts[indexPath.row]
        guard let product = savedProduct.product else{return cell!}
        cell?.productImageView.image = nil
        cell?.priceLbl.text = nil
        cell?.usernameLbl.text = nil
        cell?.likesLbl.text = nil
        cell?.productNameLbl.text = nil
        cell?.likesView.isHidden = true
        cell?.savedProduct = nil
        cell?.cartVC = nil
        
        cell?.productImageView.backgroundColor = ColorCompatibility.secondarySystemBackground
        cell?.quantityView.isHidden = false
        cell?.sizingLbl.isHidden = false
        
        DispatchQueue(label: "explore").async {
            if let dp = cache.imageFromMemoryCache(forKey: "thumbnail_\(product.productID)"){
                DispatchQueue.main.async {
                    cell?.productImageView.image = dp
                }
            }
        }
        cell?.productImageView.backgroundColor = UIColor(named: product.templateColor)
        cell?.productImageView.backgroundColor = UIColor(named: product.templateColor)
        cell?.productNameLbl.text = product.name
        cell?.savedProduct = savedProduct
        cell?.cartVC = self
        
        if product.price != nil{
            var price = "$\(product.price ?? 20.00)"
            if price.count == 5{
                price = price + "0"
            }
            cell?.priceLbl.text = "\(price)"
        }
        cell?.sizingLbl.text = "Size: \(savedProduct.size ?? "M")"
        cell?.quantityField.text = "\(savedProduct.quantity ?? 0)"
        
        if let username = product.username{
            cell?.usernameLbl.text = "@\(username)"
        }
        else{
            if let same = savedProducts.first(where: {$0.product.uid == product.uid}), let username = same.product.username{
                product.username = username
                product.fullName = same.product.fullName
                cell?.usernameLbl.text = "@\(username)"
            }
            else{
                downloadUserInfo(uid: product.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: true, downloader: downloader, userInfoToUse: nil, queryOnUsername: false, completed: { uid, fullName, username, dpID, notifID, bio, image, userFollowing, usersBlocking, postCount, followersCount, followingCount in
                    guard let username = username else{
                        
                        return}
                    for post in self.savedProducts{
                        if post.product.uid == product.uid{
                            post.product.username = username
                            post.product.fullName = fullName
                            cell?.usernameLbl.text = "@\(username)"
                        }
                        else{
                            
                        }
                    }
                })
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            
            self.savedProducts.remove(at: indexPath.row)
            
            DispatchQueue.main.async {
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }, completion: { finished in
                    if finished{
                        self.uploadToFirestore()
                    }
                })
            }
        }
    }
    
    func uploadToFirestore(){
        guard let uid = userInfo.uid else{
            
            return}

        let ref = Firestore.firestore().collection("Users/\(uid)/Cart_Info/").document("Cart_List")
        
        var finalData = [[String : Any]]()
        
        for item in savedProducts{
            
            let data = [
                "Post_ID" : item.product.productID,
                "Qty" : item.quantity ?? 0,
                "Size" : item.size ?? 0,
                "Timestamp" : item.timestamp ?? 0,
                "UID" : item.product.uid
                ] as [String : Any]
            finalData.append(data)
        }
        let dataToUpload = ["Cart_List" : finalData]
        ref.setData(dataToUpload)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fullVC: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)

        if let full: FullProductVC = fullVC.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
            full.fullProduct = savedProducts[indexPath.row].product
            navigationController?.pushViewController(full, animated: true)
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        
    }
}

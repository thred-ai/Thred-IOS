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
import PopupDialog
import FirebaseFirestore

let defaultProductType = "ATC1000"

class ProductInCart{
    
    var product: Product!
    var size: String!
    var quantity: Int!
    var isDeleted: Bool
    var timestamp: Date!
    var timestampDiff: String!
    var saleID: String!
    var inBank: Bool?
    
    init(product: Product?, size: String!, quantity: Int!, isDeleted: Bool, timestamp: Date!, timestampDiff: String?, saleID: String?, inBank: Bool?) {
        self.product = product
        self.size = size
        self.quantity = quantity
        self.isDeleted = isDeleted
        self.timestamp = timestamp
        self.timestampDiff = timestampDiff
        self.saleID = saleID
        self.inBank = inBank
    }
    convenience init() {
        self.init(product: nil, size: nil, quantity: nil, isDeleted: false, timestamp: nil, timestampDiff: nil, saleID: nil, inBank: nil)
    }
}

class ShoppingCartVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var checkoutBtn: UIButton!
    @IBOutlet weak var priceBackgroundView: UIView!
    
    @IBOutlet weak var priceLoadingView: UIView!
    @IBOutlet weak var spinner: MapSpinnerView!
    @IBOutlet weak var freeShippingLbl: UILabel!
    @IBOutlet weak var subtotalLbl: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.delegate = self
        setKeyBoardNotifs()
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else{return}
        tableView.deselectRow(at: selectedIndexPath, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        priceBackgroundView.layer.cornerRadius = priceBackgroundView.frame.height / 8
        priceBackgroundView.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = view.safeAreaInsets.bottom
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                let keyboardFrame = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardFrame.height
                UIView.animate(withDuration: 0.2, animations: {
                    if self.tableView.contentInset.bottom == 0{
                        self.tableView.contentOffset.y -= keyboardHeight - bottomPadding
                    }
                    self.tableView.contentInset.bottom = keyboardHeight - bottomPadding
                    self.tableView.verticalScrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
                }, completion: { finished in
                    if finished{}
                })
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.contentInset.bottom = 0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0
            })
        }
    }
    
    
    
    var savedProducts = [ProductInCart]()
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
        checkoutBtn.isEnabled = false
        checkoutBtn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        showPriceSpinner()
        downloadCart {
            self.hidePriceSpinner()
            self.setSubtotal()
        }
    }
    
    func showPriceSpinner(){
        priceLoadingView.isHidden = false
        spinner.animate()
    }
    
    func hidePriceSpinner(){
        priceLoadingView.isHidden = true
    }
    
    func calculateSubtotal() -> Double{
        var subtotal = 0.00
        
        for product in savedProducts{
            guard let price = product.product.price, let quantity = product.quantity else{continue}
            subtotal += price * Double(quantity)
        }
        return subtotal
    }
    
    func setSubtotal(){
        subtotalLbl.text = calculateSubtotal().formatPrice()
        
        if isFreeShipping(){
            freeShippingLbl.text = "Your order qualifies for free shipping!"
        }
        else{
            let remaining = 5 - savedProducts.compactMap({$0.quantity}).reduce(0, +)
            var grammar = "s"
            if remaining == 1{
                grammar = ""
            }
            freeShippingLbl.text = "Order \(remaining) more product\(grammar) and you'll qualify for free shipping!"
        }
    }
    
    func isFreeShipping() -> Bool{
        return (5 - savedProducts.compactMap({$0.quantity}).reduce(0, +)) <= 0
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
        return 85
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    lazy var headerView: UIView? = {
        
        return loadCartHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if savedProducts.isEmpty{
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
        if savedProducts.isEmpty{
            return 150
        }
        return 0
    }
    
    @IBAction func checkOut(_ sender: UIButton) {
        guard !savedProducts.isEmpty else{return}
        guard checkIfCardSet() else{ showBankConfirmationMessage {}; return}
        guard checkDeletedProducts(), checkPrivateProducts()
        else{
            showDeletedConfirmationMessage {
                self.performSegue(withIdentifier: "toCheckout", sender: nil)
            }
            return
        }
        self.performSegue(withIdentifier: "toCheckout", sender: nil)
    }
    
    func checkDeletedProducts() -> Bool{
        if savedProducts.contains(where: {!($0.product.isAvailable)}){
            return false
        }
        return true
    }
    
    func checkPrivateProducts() -> Bool{
        if savedProducts.contains(where: {!($0.product.isPublic) && ($0.product.userInfo.uid != userInfo.uid)}){
            return false
        }
        return true
    }
    
    func showBankConfirmationMessage(completed: @escaping () -> ()){
        
        let title = "Billing Information Not Set"
        let message = "Add a billing card to purchase products from Thred, you can do this in account settings."
        let titleColor = UIColor.label
        
        let yesBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }

        showPopUp(title: title, message: message, image: nil, buttons: [yesBtn], titleColor: titleColor)
    }
    
    func showDeletedConfirmationMessage(completed: @escaping () -> ()){
        
        let title = "Your order contains products that were deleted"
        let message = "These will be excluded from your order upon checkout."
        let titleColor = UIColor.label
        
        let yesBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }

        showPopUp(title: title, message: message, image: nil, buttons: [yesBtn], titleColor: titleColor)
    }
    
    func checkIfCardSet() -> Bool{
                
        if UserDefaults.standard.string(forKey: "CARD_BRAND") != nil, UserDefaults.standard.string(forKey: "CARD_LAST_4") != nil, UserDefaults.standard.string(forKey: "CARD_POSTAL_CODE") != nil{
            return true
        }
        return false
    }
    
    var isLoading = true
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl?){
                
        showPriceSpinner()
        guard checkInternetConnection() else{
            sender?.endRefreshing()
            hidePriceSpinner()
            setSubtotal()
            return
        }
        
        if !isLoading{
            isLoading = true
            sender?.animateRefresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.savedProducts.removeAll()
                self.downloadCart {
                    self.isLoading = false
                    self.hidePriceSpinner()
                    self.setSubtotal()
                    DispatchQueue.main.async {
                        sender?.endRefreshing()
                    }
                }
            }
        }
        else{
            sender?.endRefreshing()
        }
    }
    
    func downloadCart(completed: @escaping () -> ()){
        self.getCartList(completed: { productList in
            if let products = productList{
                self.savedProducts.append(contentsOf: products)
                self.getProducts(isRefreshing: true){ hasDocs in
                    if hasDocs{
                        if !self.savedProducts.filter({$0.product.isAvailable ?? false}).isEmpty{
                            self.checkoutBtn.isEnabled = true
                        }
                    }
                    self.isLoading = false
                    self.tableView.reloadData()
                    completed()
                }
            }
            else{
                self.isLoading = false
                self.tableView.reloadData()
                completed()
            }
        })
    }

    
    var downloadingPictures = [String]()

    func getProducts(isRefreshing: Bool, completed: @escaping (Bool) -> ()){
        
        let productIDs = savedProducts.compactMap({$0.product}).compactMap({$0.productID})
        
        
        guard !productIDs.isEmpty else{
            
            completed(false); return}
        
        print(productIDs)
        
        for (index, id) in productIDs.enumerated(){
            
            guard let userUID = userInfo.uid else{return}
            let currentCartProduct = self.savedProducts[index]

            if let same = savedProducts.first(where: {$0.product.productID == id && $0.product.name != nil}){
                currentCartProduct.product = same.product
                continue
            }
            
            let query = Firestore.firestore().collectionGroup("Products").whereField("Product_ID", isEqualTo: id).order(by: "Timestamp")
            
            query.getDocuments(completion: { snaps, error in
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                    guard let snap = snaps?.documents.first else{
                        completed(false)
                        return}
                    let isAvailable = snap["Available"] as? Bool
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
                    let isPublic = snap["Public"] as? Bool ?? true
                    let productType = snap["Type"] as? String ?? defaultProductType
                    let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: index, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil, isAvailable: isAvailable, isPublic: isPublic, productType: productType)
                    
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
                        currentCartProduct.product = product
                        let downloaded = self.savedProducts.compactMap({$0.product.name})
                        if downloaded.count == productIDs.count{
                            completed(true)
                        }
                        if !self.downloadingPictures.contains(snap.documentID){
                            self.downloadingPictures.append(snap.documentID)
                            let ref = Storage.storage().reference().child("Users/" + uid + "/" + "Products/" + snap.documentID + "/" + "thumbnail_\(snap.documentID)" + ".png")
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
                    })
                }
            })
        }
    }
    
    
    func getCartList(completed: @escaping ([ProductInCart]?) -> ()){
        
        guard let uid = userInfo.uid else{return}

        Firestore.firestore().collection("Users").document(uid).collection("Cart_Info").document("Cart_List").getDocument(completion: { doc, error in
            
            if let err = error{
                completed(nil)
                print(err.localizedDescription)
            }
            else{
                guard let doc = doc else{return}
                var localLoaded = [ProductInCart]()
                guard let cartList = doc["Cart_List"] as? [[String : Any]] else{
                    completed(nil)
                    return
                }
                
                for product in cartList{
                    let uid = product["UID"] as! String
                    let size = product["Size"] as? String ?? "M"
                    let qty = product["Qty"] as? Int ?? 1
                    let timestamp = (product["Timestamp"] as? Timestamp)?.dateValue()
                    guard let productID = product["Post_ID"] as? String else{continue}
                    if userInfo.usersBlocking.contains(uid){
                        continue
                    }

                    let product = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: productID, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: userInfo.userLiked.contains(doc.documentID), designImage: nil, comments: nil, link: nil, isAvailable: false, isPublic: nil, productType: nil)
                    let productInCart = ProductInCart(product: product, size: size, quantity: qty, isDeleted: false, timestamp: timestamp, timestampDiff: nil, saleID: nil, inBank: nil)
                    localLoaded.append(productInCart)
                }
                completed(localLoaded)
            }
        })
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedProducts.count
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.delegate = self
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchProductCell", for: indexPath) as? SearchProductTableViewCell
        guard self.savedProducts.indices.contains(indexPath.row) else{return cell!}
        let savedProduct = self.savedProducts[indexPath.row]
        guard let product = savedProduct.product else{return cell!}
        cell?.productImageView.image = nil
        cell?.priceLbl.text = nil
        cell?.likesLbl.text = nil
        cell?.productNameLbl.text = nil
        cell?.likesView.isHidden = true
        cell?.savedProduct = nil
        cell?.cartVC = nil
        cell?.sizingLbl.text = nil
        cell?.productImageView.backgroundColor = .secondarySystemBackground
        cell?.sizingLbl.isHidden = false
        cell?.quantityView.isHidden = true
        cell?.isDeleted = false
        cell?.isUserInteractionEnabled = false

        if let color = product.templateColor, let name = product.name, let price = product.price{
            cell?.quantityView.isHidden = false
            cell?.isUserInteractionEnabled = true
            cell?.isDeleted = !(product.isAvailable ?? false)
            cell?.productImageView.backgroundColor = UIColor(named: color)
            cell?.productNameLbl.text = name
            cell?.priceLbl.text = price.formatPrice()

            cell?.sizingLbl.text = "Size: \(savedProduct.size ?? "M")"
            cell?.quantityField.text = "\(savedProduct.quantity ?? 0)"
            cell?.quantityField.textColor = UIColor(named: "LoadingColor")
             
            cell?.savedProduct = savedProduct
            cell?.cartVC = self
             
            DispatchQueue(label: "explore").async {
                if let dp = cache.imageFromMemoryCache(forKey: "thumbnail_\(product.productID)"){
                    DispatchQueue.main.async {
                        cell?.productImageView.image = dp
                    }
                }
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
                        if self.savedProducts.isEmpty{
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                })
            }
        }
    }                                

    
    func uploadToFirestore(){
        guard let uid = userInfo.uid else{
            return}
        checkoutBtn.isEnabled = false
        showPriceSpinner()
        let ref = Firestore.firestore().collection("Users/\(uid)/Cart_Info/").document("Cart_List")
        
        var finalData = [[String : Any]]()
        
        
        for item in savedProducts{
            
            guard let postUID = item.product.userInfo.uid else{
            continue}
            
            let data = [
                "Post_ID" : item.product.productID,
                "Qty" : item.quantity ?? 0,
                "Size" : item.size ?? 0,
                "Timestamp" : item.timestamp ?? 0,
                "UID" : postUID
                ] as [String : Any]
            finalData.append(data)
        }
        let dataToUpload = ["Cart_List" : finalData]
        ref.setData(dataToUpload, completion: { error in
            if let err = error{
                print(err.localizedDescription)
                self.refresh(nil)
                if !self.savedProducts.filter({$0.product.isAvailable ?? false}).isEmpty{
                    self.checkoutBtn.isEnabled = true
                    self.hidePriceSpinner()
                    self.setSubtotal()
                }
            }
            else{
                if !self.savedProducts.filter({$0.product.isAvailable ?? false}).isEmpty{
                    self.checkoutBtn.isEnabled = true
                }
                self.hidePriceSpinner()
                self.setSubtotal()
            }
        })
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
        
        if let vc = segue.destination as? CheckoutVC{
            vc.savedProducts = savedProducts
            .filter({
                $0.product.isAvailable
                })
            .filter({
                !(
                    !($0.product.isPublic) &&
                    ($0.product.userInfo.uid != userInfo.uid)
                )
            })
        }
    }
}

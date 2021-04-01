//
//  FullProductVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-02.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseFirestore
import ColorCompatibility
import Firebase
import FirebaseAnalytics


class FullProductVC: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var addToCartBtn: UIButton!
    var selectedSize: String!
    var editedPost = false
    var hashtagToOpen: Hashtag?
    
    @IBOutlet weak var deletedView: UIView!
    
    var isDeleted: Bool! = false{
        didSet{
            if isDeleted{
                addToCartBtn.isEnabled = false
                deletedView.isHidden = false
            }
            else{
                addToCartBtn.isEnabled = true
                deletedView.isHidden = true
            }
        }
    }
    
    @IBAction func addToCart(_ sender: UIButton) {
        
        sender.isEnabled = false

        if sender.currentTitle == "VIEW MY CART"{
            navigationController?.segueToCart()
            sender.setTitle("BUY NOW", for: .normal)
            sender.isEnabled = true
            return
        }
        
        Analytics.logEvent("added_to_cart", parameters: [
            "name": "Add to Cart",
            "full_text": "User added to cart"
        ])
        
        UIView.animate(withDuration: 0.2, animations: {
            sender.setTitle("VIEW MY CART", for: .normal)
        }, completion: { finished in
            if finished{
                sender.isEnabled = true
            }
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
            UIView.animate(withDuration: 0.2, animations: {
                sender.setTitle("BUY NOW", for: .normal)
            })
        }
        
        let size = selectedSize ?? "M"
        guard let uid = pUserInfo.uid else{
            return}
        guard let postUID = fullProduct.userInfo.uid else{
            return}
        
        let mappedData = [
            "UID" : postUID,
            "Size" : size,
            "Qty" : 1,
            "Timestamp" : Date(),
            "Post_ID" : fullProduct.productID
            ] as [String : Any]
        
        let data = [
            "Cart_List" : FieldValue.arrayUnion([mappedData])
        ]
        
        Firestore.firestore().collection("Users/\(uid)/Cart_Info").document("Cart_List").setData(data, merge: true, completion: { error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
            }
        })
    }
    
    
    
    
    var fullProduct = Product()
    var selectedComment: Comment!
    var friendInfo: UserInfo! = UserInfo()
    
    @IBAction func toCart(_ sender: UIBarButtonItem) {
        
        navigationController?.segueToCart()
    }
       
    @IBAction func toSales(_ sender: UIBarButtonItem) {
           navigationController?.segueToSales()
    }

    @IBOutlet weak var tableView: UITableView!

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        deletedView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        isDeleted = false
        addToCartBtn.isEnabled = false
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.delegate = self
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        
        
        getProduct()
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    func scrollToBottom(){
        guard selectedComment == nil, fullProduct.isAvailable else{return}
        let lastSection = tableView.numberOfSections - 3
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        let lastIndexPath = IndexPath(row: lastRow, section: lastSection)
        
        print(lastIndexPath)
        
        DispatchQueue.main.async {
            self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
        }
    }
    
    
    lazy var backgroundView: UIView = {
        let view = UIView.init(frame: tableView.bounds)
        
        let spinner = MapSpinnerView.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.animate()
        return view
    }()
    
    
    func getProduct(){
        
        guard let userUID = pUserInfo.uid else{return}
        
        let query = Firestore.firestore().collectionGroup("Products").whereField("Product_ID", isEqualTo: fullProduct.productID).order(by: "Timestamp")
        
        query.getDocuments(completion: { snaps, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                if snaps?.isEmpty ?? true{
                    self.navigationController?.popViewController(animated: true)
                }
                else{
                    guard let snap = snaps?.documents.first else{
                        self.navigationController?.popViewController(animated: true)
                        return}
                    let isAvailable = snap["Available"] as? Bool
                    let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                    let uid = snap["UID"] as! String
                    
                    if pUserInfo.usersBlocking.contains(uid){
                        print(uid)
                        print(pUserInfo.usersBlocking)
                        
                        self.navigationController?.popViewController(animated: true)
                        return
                    }
                    
                    let description = snap["Description"] as? String
                    let name = snap["Name"] as? String
                    let blurred = snap["Blurred"] as? Bool
                    let templateColor = snap["Template_Color"] as? String
                    let likes = snap["Likes"] as? Int
                    guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                    let comments = ((snap["Comments"]) as? Int) ?? 0
                    let isPublic = snap["Public"] as? Bool ?? true
                    let productType = snap["Type"] as? String ?? defaultProductType
                    let displaySide = snap["Side"] as? String ?? "front"
                    let sides = snap["Sides"] as? [String] ?? ["Front"]

                    guard !(!isPublic && uid != pUserInfo.uid) else{
                        self.navigationController?.popViewController(animated: true)
                        return
                    }
                    
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
                        
                        self.fullProduct = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: snap.documentID, description: description, productID: snap.documentID, timestamp: timestamp, index: nil, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: nil, comments: comments, link: nil, isAvailable: isAvailable, isPublic: isPublic, productType: productType, displaySide: displaySide, supportedSides: sides)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.scrollToBottom()
                        }
                    })
                }
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        addToCartBtn.layer.cornerRadius = addToCartBtn.frame.height / 8
        addToCartBtn.clipsToBounds = true
        tableView.backgroundView = backgroundView
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 1000
    }
    
    
    var isRasterizing = false
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isRasterizing{
            return false
        }
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setKeyBoardNotifs()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        hideCenterBtn()
    }
    
    
    
    
    
    
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        guard editedPost else{
        return}
        if let products = ((viewController as? FeedVC)?.loadedProducts ?? (viewController as? FriendVC)?.loadedProducts ?? (viewController as? UserVC)?.loadedProducts){
            
            guard let index = products.firstIndex(where: {$0.productID == fullProduct.productID}) else{
                return}
            products[index].name = fullProduct.name
            products[index].description = fullProduct.description
            products[index].price = fullProduct.price
            products[index].isPublic = fullProduct.isPublic
                
            let tableView = (viewController as? FeedVC)?.tableView
            
            tableView?.performBatchUpdates({
                tableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }, completion: nil)
        }
        else{
            
        }
    }


    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    // MARK: - Table view data source

    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if fullProduct.name == nil{
            return 1
        }
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if fullProduct.name == nil{
            return 0
        }
        return 1
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PictureProduct", for: indexPath) as? ProductCell
            tableView.setPictureCell(cell: cell, indexPath: indexPath, product: fullProduct, productLocation: self, shouldDownloadPic: true)
            return cell!
        }
        else if indexPath.section == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "sizeCell", for: indexPath) as? SizeCell
            cell?.vc = self
            cell?.setUp()
            return cell!
        }
        else if indexPath.section == 2{
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "infoCell")
            cell.textLabel?.font = UIFont(name: "NexaW01-Heavy", size: 12)
            cell.detailTextLabel?.font = UIFont(name: "NexaW01-Regular", size: cell.detailTextLabel?.font.pointSize ?? 16)
            
            cell.textLabel?.text = "Product Type:"
            
            guard let sameType = all.tees.first(where: {$0.productCode == fullProduct.productType}), let info = sameType.info, let colorName = sameType.colors.first(where: {$0.code == fullProduct.templateColor})?.display
            else {return cell}
            
            cell.detailTextLabel?.text = "\(info) (\(colorName))"
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "info", for: indexPath) as? ProductInfoCell
            guard let sameType = all.tees.first(where: {$0.productCode == fullProduct.productType}) else{return cell!}
            cell?.infoLbl.text = "\((sameType.templateDisplayName ?? "").lowercased().capitalized) Details"
            cell?.infoView?.text = sameType.moreInfo
            return cell!
        }
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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let friendVC = segue.destination as? FriendVC{
            friendVC.friendInfo = friendInfo
        }
        if let commentsVC = segue.destination as? CommentsVC{
            commentsVC.post = fullProduct
            commentsVC.selectedComment = selectedComment
            selectedComment = nil
        }
        else if let designVC = (segue.destination as? UINavigationController)?.viewControllers.first as? DesignInfoViewController{
            
            var designs = [Design]()
            guard let sameTemplate = all.tees.first(where: {$0.productCode == fullProduct.productType}) else{return}
            for side in fullProduct.supportedSides.filter({$0 == fullProduct.displaySide.capitalizingFirstLetter()}){
                
                var design: Design!
                var prefix = ""
                if side == "Back"{
                    prefix = "BACK_"
                }
                var img: Data!
                if let fullIMG = cache.imageFromCache(forKey: "\(prefix)\(fullProduct.productID)")?.pngData(){
                    img = fullIMG
                }
                else if let thumbIMG = cache.imageFromCache(forKey: "thumbnail_\(prefix)\(fullProduct.productID)")?.pngData(){
                    img = thumbIMG
                }
                guard let side = sameTemplate.supportedSides.first(where: {$0.name == side}) else{return}
                design = Design(img: img, side: side)
                designs.append(design)
            }
            
            designVC.product = ProductInProgress(templateColor: fullProduct.templateColor, designs: designs, uid: fullProduct.userInfo.uid, caption: fullProduct.description, name: fullProduct.name, price: fullProduct.price, productID: fullProduct.productID, display: fullProduct.designImage, isPublic: fullProduct.isPublic, productType: fullProduct.productType, displaySide: fullProduct.displaySide)
            designVC.isEditingProduct = true
        }
        else if let reportVC = (segue.destination as? UINavigationController)?.viewControllers.first as? ReportVC{
            reportVC.reportLevel = .post
            reportVC.reportPostID = fullProduct.productID
            reportVC.reportUID = fullProduct.userInfo.uid
        }
        else if let colorSectionVC = segue.destination as? ColorSectionVC{
            colorSectionVC.hashtag = hashtagToOpen
        }
    }

}

extension UIViewController{
    func showCenterBtn(){
        if let button = (self.tabBarController as? MainTabBarViewController)?.button, let spinner = (self.tabBarController as? MainTabBarViewController)?.spinner, let bubble = (self.tabBarController as? MainTabBarViewController)?.speechBubble{
            if button.isHidden{
                button.isHidden = false
                (self.tabBarController as? MainTabBarViewController)?.checktoHideBubble()
                UIView.animate(withDuration: 0.2, animations: {
                    button.alpha = 1.0
                    spinner.alpha = 1.0
                    bubble.alpha = 1.0
                }, completion: { finished in
                    if finished{
                    }
                })
            }
        }
    }
    
    func hideCenterBtn(){
        if let button = (self.tabBarController as? MainTabBarViewController)?.button, let spinner = (self.tabBarController as? MainTabBarViewController)?.spinner, let bubble = (self.tabBarController as? MainTabBarViewController)?.speechBubble{
            if !button.isHidden{
                UIView.animate(withDuration: 0.2, animations: {
                    button.alpha = 0.0
                    spinner.alpha = 0.0
                    bubble.alpha = 0.0
                }, completion: { finished in
                    if finished{
                        button.isHidden = true
                        spinner.isHidden = true
                        bubble.isHidden = true
                    }
                })
            }
        }
    }
}

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


class FullProductVC: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var addToCartBtn: UIButton!
    var selectedSize: String!
    
    
    @IBAction func addToCart(_ sender: UIButton) {
        
        sender.isEnabled = false
        UIView.animate(withDuration: 0.2, animations: {
            sender.setTitle("Added item to cart", for: .normal)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
            UIView.animate(withDuration: 0.2, animations: {
                sender.setTitle("Add to cart", for: .normal)
            }, completion: { finished in
                if finished{
                    sender.isEnabled = true
                }
            })
        }
        
        let size = selectedSize ?? "M"
        guard let uid = userInfo.uid else{
            
            return}
        
        let mappedData = [
            "UID" : fullProduct.uid,
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
    var downloader: SDWebImageDownloader? = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
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
        downloader?.invalidateSessionAndCancel(true)
        downloader = nil
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        
       
    }
    
    override func viewDidLayoutSubviews() {
        addToCartBtn.layer.cornerRadius = addToCartBtn.frame.height / 8
        addToCartBtn.clipsToBounds = true
        
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
        if downloader == nil{
            downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        if navigationController != nil{
           navigationController?.delegate = self // Update assignment here
        }
        else {
            print("navigation controller does not exist")
        }
        hideCenterBtn()
    }
    
    
    
    
    
    
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if let viewController = viewController as? UITableViewController{
            if let index = ((viewController as? FeedVC)?.loadedProducts ?? (viewController as? FriendVC)?.loadedProducts ?? (viewController as? UserVC)?.loadedProducts)?.firstIndex(where: {$0.productID == fullProduct.productID}){
                viewController.tableView.performBatchUpdates({
                    viewController.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }, completion: nil)
            }
        }
    }

    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        guard let uid = userInfo.uid else{return}
        if viewController == self{
            guard let index = navigationController.viewControllers.firstIndex(of: self) else{return}
            let vc = navigationController.viewControllers[index - 1]
            if vc is ExploreViewController || vc is ColorSectionVC{
                
                let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProductCell
                cell?.isUserInteractionEnabled = false
                    
                if !(userInfo.userLiked.contains(fullProduct.productID)){
                    Firestore.firestore().collection("Users").document(fullProduct.uid).collection("Products").document(fullProduct.productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: uid).getDocuments(completion: { snapLikes, error in
                        
                        var liked: Bool!
                        
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            userInfo.userLiked.removeAll(where: {$0 == self.fullProduct.productID})
                            if let likeDocs = snapLikes?.documents{
                                if likeDocs.isEmpty{
                                    liked = false
                                }
                                else{
                                    liked = true
                                    if !(userInfo.userLiked.contains(self.fullProduct.uid)){
                                        userInfo.userLiked.append(self.fullProduct.uid)
                                    }
                                }
                            }
                            else{
                                liked = false
                            }
                        }
                        cell?.isUserInteractionEnabled = true
                        UserDefaults.standard.set(userInfo.userLiked, forKey: "LikedPosts")
                        self.fullProduct.liked = liked
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    })
                }
                
            }
        }
    }
    
    func rasterizeProductCellDisplay(cell: ProductCell?, image: UIImage?, product: Product?){
        isRasterizing = true
        cell?.canvasDisplayView.isHidden = false
        cell?.canvasDisplayView.image = image
        let bundlePath = Bundle.main.path(forResource: product?.templateColor, ofType: "png")
        let img = UIImage(contentsOfFile: bundlePath!)
        cell?.productPicture.image = img
        cell?.productPicture.addShadowToImageNotLayer()
        cell?.circularProgress.removeFromSuperview()
        navigationController?.navigationBar.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let fullData = cell?.productPicture.makeSnapshot(clear: true, subviewsToIgnore: [])?.pngData()
            cell?.canvasDisplayView.isHidden = true
            self.navigationController?.navigationBar.isUserInteractionEnabled = true

            self.navigationItem.hidesBackButton = false
            self.fullProduct.designImage = fullData
            guard let fullImgData = fullData else{return}
            cell?.productPicture.image = UIImage(data: fullImgData)
            self.isRasterizing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if self.selectedComment != nil{
                self.performSegue(withIdentifier: "toComments", sender: nil)
            }
        }
    }
    
    

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    // MARK: - Table view data source

    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0{
            return tableView.setPictureCell(indexPath: indexPath, product: fullProduct, productLocation: self)
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "sizeCell", for: indexPath) as? SizeCell
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
        else if let designVC = (segue.destination as? UINavigationController)?.viewControllers.first as? DesignViewController{
            if let img = cache.imageFromCache(forKey: fullProduct.productID){
                designVC.product = ProductInProgress(templateColor: fullProduct.templateColor, design: img, uid: fullProduct.uid, caption: fullProduct.description, name: fullProduct.name, price: fullProduct.price, productID: fullProduct.productID)
            }
        }
        else if let reportVC = (segue.destination as? UINavigationController)?.viewControllers.first as? ReportVC{
            reportVC.reportLevel = .post
            reportVC.reportPostID = fullProduct.productID
            reportVC.reportUID = fullProduct.uid
        }
    }

}

extension UIViewController{
    func showCenterBtn(){
        if let button = (self.tabBarController as? MainTabBarViewController)?.button{
            if button.isHidden{
                button.isHidden = false
                UIView.animate(withDuration: 0.2, animations: {
                    button.alpha = 1.0
                }, completion: { finished in
                    if finished{
                    }
                })
            }
        }
    }
    
    func hideCenterBtn(){
        if let button = (self.tabBarController as? MainTabBarViewController)?.button{
            if !button.isHidden{
                UIView.animate(withDuration: 0.2, animations: {
                    button.alpha = 0.0
                }, completion: { finished in
                    if finished{
                        button.isHidden = true
                    }
                })
            }
        }
    }
}

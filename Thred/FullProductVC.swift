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


class FullProductVC: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var addToCartBtn: UIButton!
    
    
    @IBAction func addToCart(_ sender: UIButton) {
    }
    
    
    var fullProduct = Product()
    var downloader: SDWebImageDownloader? = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
    
    var friendInfo: UserInfo! = UserInfo()

    @IBOutlet weak var tableView: UITableView!

    override func viewDidDisappear(_ animated: Bool) {
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
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self

        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        cache.removeImageFromMemory(forKey: fullProduct.picID)
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
        
        if downloader == nil{
            downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
        }
        getProduct {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        if self.navigationController != nil{
           self.navigationController?.delegate = self // Update assignment here
        }
        else {
            print("navigation controller does not exist")
        }
        hideCenterBtn()
    }
    
    
    func getProduct(completed: @escaping () -> ()){
        Firestore.firestore().collection("Users").document(fullProduct.uid).collection("Products").document(fullProduct.productID).getDocument(completion: { doc, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
                completed()
            }
            else{
                
                guard let snap = doc else{return}
                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                let uid = snap["UID"] as! String
                let description = snap["Description"] as? String
                let name = snap["Name"] as? String
                let blurred = snap["Blurred"] as? Bool
                let templateColor = snap["Template_Color"] as? String
                let likes = snap["Likes"] as? Int
                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                
                Firestore.firestore().collection("Users").document(self.fullProduct.uid).collection("Products").document(self.fullProduct.productID).collection("Likes").whereField(FieldPath.documentID(), isEqualTo: userInfo.uid).getDocuments(completion: { snaps, error in
                    
                    var liked: Bool!
                    
                    EmptyDocuments:
                    if error != nil{
                        
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        guard let docs = snaps?.documents, !docs.isEmpty else{
                            liked = false
                            userInfo.userLiked?.removeAll(where: {$0 == snap.documentID})
                            break EmptyDocuments
                        }
                        
                        liked = true
                        if (userInfo.userLiked?.contains(snap.documentID) ?? true){
                            userInfo.userLiked?.append(snap.documentID)
                        }
                    }
                    let product = Product(uid: uid, picID: snap.documentID, description: description, fullName: self.fullProduct.fullName, username: self.fullProduct.username, productID: snap.documentID, userImageID: self.fullProduct.userImageID, timestamp: timestamp, index: nil, timestampDiff: self.fullProduct.timestampDiff, fromCache: false, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: liked, designImage: self.fullProduct.designImage)
                    self.fullProduct = product
                    completed()
                })
            }
        })
    }
    
    
    
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if !(viewController.hidesBottomBarWhenPushed){
        }
        else{
        }
    }

    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        
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
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
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
    }
    
    

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    // MARK: - Table view data source

    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.setPictureCell(indexPath: indexPath, product: fullProduct, productLocation: self)
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

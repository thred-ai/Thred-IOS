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
    var selectedComment: Comment!
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
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        
        if let vcs = navigationController?.viewControllers{
            if vcs.indices.contains(vcs.count - 2){
                let secondLastVC = vcs[vcs.count - 2]
                if !(secondLastVC.isKind(of: UserVC.self) || secondLastVC.isKind(of: FeedVC.self)){
                    cache.removeImageFromMemory(forKey: fullProduct.picID)
                }
            }
        }
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
        if !(viewController.hidesBottomBarWhenPushed){
        }
        else{
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

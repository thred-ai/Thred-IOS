//
//  FullProductVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-02.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import SDWebImage



class FullProductVC: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var addToCartBtn: UIButton!
    
    
    @IBAction func addToCart(_ sender: UIButton) {
    }
    
    
    var fullProduct = Product()
    var downloader: SDWebImageDownloader? = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
    
    var friendInfo = UserInfo()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidDisappear(_ animated: Bool) {
        downloader?.invalidateSessionAndCancel(true)
        downloader = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "PictureProduct")
        cache.removeImageFromMemory(forKey: fullProduct.picID)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        addToCartBtn.layer.cornerRadius = addToCartBtn.frame.height / 8
        addToCartBtn.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        hideCenterBtn()
    }
    
    func hideCenterBtn(){
        if let button = (self.tabBarController as? MainTabBarViewController)?.button{
            UIView.animate(withDuration: 0.2, animations: {
                button.alpha = 0.0
            }, completion: { finished in
                if finished{
                    button.isHidden = true
                }
            })
        }
    }
    
    func showCenterBtn(){
        if let button = (self.tabBarController as? MainTabBarViewController)?.button{
            button.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                button.alpha = 1.0
            }, completion: { finished in
                if finished{
                }
            })
        }
    }
    
    

    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if viewController != self{
            showCenterBtn()
        }
    }
    
    func rasterizeProductCellDisplay(cell: ProductCell?, image: UIImage?, product: Product?){
        cell?.canvasDisplayView.isHidden = false
        cell?.canvasDisplayView.image = image
        cell?.productPicture.image = UIImage(named: product?.templateColor ?? "nil")
        cell?.circularProgress.removeFromSuperview()
        cell?.productPicture.superview?.backgroundColor = cell?.productPicture.backgroundColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let fullData = cell?.productPicture.makeSnapshot(clear: true, subviewsToIgnore: [])?.pngData()
            cell?.canvasDisplayView.isHidden = true
            self.fullProduct.designImage = fullData
            guard let fullImgData = fullData else{return}
            cell?.productPicture.image = UIImage(data: fullImgData)
            cell?.productPicture.superview?.backgroundColor = .clear
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
        return tableView.setPictureCell(indexPath: indexPath, user: fullProduct, productLocation: self)
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

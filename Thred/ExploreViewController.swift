//
//  ExploreViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-01-16.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import Stripe
import SDWebImage

class ExploreViewController: UITableViewController{

    var colorSections = [[String : Any?]]()
    
    var downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)
    var productToOpen: Product!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UINib(nibName: "ExploreColorCell", bundle: nil), forCellReuseIdentifier: "ExploreColorCell")
        // Do any additional setup after loading the view.
        
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
       
        tableView.addSubview(refresher)
        
        getTemplates{_ in
            self.isLoading = false
        }
    }
    
     
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        showCenterBtn()

        guard productToOpen != nil else{return}
        
        for section in colorSections{
            tableView.syncPostLikes(loadedProducts: section["Array"] as? [Product] ?? [], vc: self)
        }

        guard let colorSection = self.colorSections.first(where: {$0["ID"] as? String == productToOpen.templateColor}) else{return}
        guard let postArray = colorSection["Array"] as? [Product] else{return}
        guard let post = postArray.first(where: {$0.productID == productToOpen.productID}) else{return}
        post.liked = productToOpen.liked
        post.likes = productToOpen.likes
        post.username = productToOpen.username
        post.fullName = productToOpen.fullName
        
    }
    
    var isLoading = false
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
                
        if !isLoading{
            isLoading = true
            if sender.isRefreshing{
                sender.animateRefresh()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.getTemplates{ error in
                    
                    if error == nil{
                        self.colorSections.removeAll()
                        cache.clearMemory()
                    }
                    self.isLoading = false
                    sender.endRefreshing()
                }
            }
        }
        else{
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return colorSections.count
    }
    
    func getTemplates(completed: @escaping (Error?) -> ()){
        Firestore.firestore().document("Templates/Tees").getDocument(completion: { snap, error in
            if error != nil{
                completed(error)
                print(error?.localizedDescription ?? "")
            }
            else{
                guard let doc = snap else{return}
                completed(nil)
                let ids = doc["IDs"] as? [String]
                for id in ids ?? []{
                    self.colorSections.append(["Array": nil, "ID": id, "Offset": 0, "Downloading" : []])
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let cell = cell as? ExploreColorCell{
            cell.collectionViewOffset = colorSections[indexPath.row]["Offset"] as? CGFloat ?? 0
           
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreColorCell", for: indexPath) as? ExploreColorCell
        
        cell?.colorIcon.backgroundColor = nil
        cell?.exploreVC = nil
        cell?.downloader = nil
        
        cell?.templateColor = nil
        
        cell?.colorIcon.backgroundColor = UIColor(named: self.colorSections[indexPath.row]["ID"] as? String ?? "null")
        cell?.exploreVC = self
        cell?.downloader = downloader
        cell?.templateColor = self.colorSections[indexPath.row]["ID"] as? String //problem

        if let postArray = self.colorSections[indexPath.row]["Array"] as? [Product]{
            cell?.postArray = postArray
        }
        else{
            cell?.postArray = nil
        }
        cell?.getProducts{
            DispatchQueue.main.async {
                cell?.collectionView.reloadData()
            }
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ExploreColorCell{
            cell.postArray.removeAll()
            cell.collectionView.reloadData()
            if colorSections.indices.contains(indexPath.row){
                colorSections[indexPath.row]["Offset"] = cell.collectionViewOffset
            }
            
        }
    }
    
    var selectedTemplateColor: String?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTemplateColor = colorSections[indexPath.row]["ID"] as? String
        self.performSegue(withIdentifier: "toColorSection", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let fullVC = segue.destination as? FullProductVC{
            fullVC.fullProduct = productToOpen
        }
        if let sectionVC = segue.destination as? ColorSectionVC{
            guard let color = selectedTemplateColor else{return}
            sectionVC.templateColor = color
        }
    }
    
    
    
    /*
    func addDebitCard(){
        let form = STPPaymentCardTextField.init(frame: CGRect(x: 10, y: 0, width: self.view.frame.width - 20, height: 45))
    }
    */

    /*
    @IBAction func testCharge(_ sender: UIButton) {
     
        let data = [
            "product_id":"akskdjsj",
            "amount": 99999900,
            "source":"tok_visa",
            "customer_id": "cus_GXHvUh9RzbfEU0",
            "merchant_id": "acct_1FyBVRAIhu8eWpr1",
            "customer_uid" : "aR6FMc9OR2VmBUrHCk8l3KQIDPj1",
            "merchant_uid" : "fB6BIMoZ38gulk7Km0ReSIVceNe2"
            ] as [String : Any]
        Functions.functions().httpsCallable("createCharge").call(data, completion: { result, error in
            
            if error != nil{
                print(error?.localizedDescription ?? "")
                
                
            }
            else{
                
                
                
            }
        })
    }
 
 */
    

}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull ?? CFNull.self])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

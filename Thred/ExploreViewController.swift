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

    var colorSections = [[String : [Product]?]]()
    var downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UINib(nibName: "ExploreColorCell", bundle: nil), forCellReuseIdentifier: "ExploreColorCell")
        // Do any additional setup after loading the view.
        
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
       
        tableView.addSubview(refresher)
        
        getTemplates{
            
        }
    }
    
    var isLoading = false
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
                
        if !isLoading{
            isLoading = true
            if sender.isRefreshing{
                sender.animateRefresh()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.colorSections.removeAll()
                self.tableView.reloadData()
                cache.clearMemory()
                self.getTemplates{
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
    
    func getTemplates(completed: @escaping () -> ()){
        Firestore.firestore().document("Templates/Tees").getDocument(completion: { snap, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                //for doc in snaps?.documents ?? []{}
                guard let doc = snap else{return}
                let ids = doc["IDs"] as? [String]
                for id in ids ?? []{
                    self.colorSections.append([id : nil])
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                completed()
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreColorCell", for: indexPath) as? ExploreColorCell
        
        cell?.colorIcon.backgroundColor = nil
        cell?.exploreVC = nil
        cell?.downloader = nil
        cell?.postArray = nil
        
        cell?.colorIcon.backgroundColor = UIColor(named: colorSections[indexPath.row].keys.first ?? "null")
        cell?.exploreVC = self
        cell?.downloader = downloader
        cell?.templateColor = self.colorSections[indexPath.row].keys.first!
        if let postArray = self.colorSections[indexPath.row][self.colorSections[indexPath.row].keys.first ?? ""]{
            cell?.postArray = postArray
        }
        cell?.getProducts()
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
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

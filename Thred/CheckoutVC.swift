//
//  CheckoutVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-05-31.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import ColorCompatibility
import CoreLocation
import PopupDialog

class CheckoutVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var payBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var savedProducts = [ProductInCart]()
    @IBOutlet weak var subtotalField: UILabel!
    @IBOutlet weak var taxShippingField: UILabel!
    @IBOutlet weak var totalField: UILabel!
    @IBOutlet weak var priceBackgroundView: UIView!
    var billingPostalCode: String!
    @IBOutlet weak var spinner: MapSpinnerView!
    @IBOutlet weak var spinnerView: UIView!
    @IBOutlet weak var shippingAndTaxLbl: UILabel!
    var orderNumber: String?
    var area: String!
    var country: String!
    
    var salesInfo = [
        "SalesTax" : 0.0,
        "Shipping" : 1200.0
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "SearchProductTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchProductCell")
        
        tableView.allowsSelection = false
        payBtn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        payBtn.isEnabled = false

        if let street = UserDefaults.standard.string(forKey: "street"), let city = UserDefaults.standard.string(forKey: "city"), let adminArea = UserDefaults.standard.string(forKey: "admin_area"), let country = UserDefaults.standard.string(forKey: "country"), UserDefaults.standard.string(forKey: "postal_code") != nil{
            showSpinner()
            let address = "\(street), \(city), \(adminArea), \(country)"
            validateAddress(address: address, completed: { country, adminArea, city, street, postalCode, isValid in
                if isValid{
                    if country == "Canada", adminArea != "BC"{
                        self.area = adminArea
                        self.country = country
                        self.calculateCosts(province: adminArea){
                            self.hideSpinner()
                            self.payBtn.isEnabled = true
                        }
                    }
                    else{
                        self.showCountryErrorView()
                    }
                }
                else{
                    self.showCountryErrorView()
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
        else{
            
        }
    }
    
    func showSpinner(){
        spinnerView.isHidden = false
        spinner.animate()
    }
    
    func hideSpinner(){
        spinnerView.isHidden = true
    }

    func showErrorView(){
        
        hideSpinner()
    }
    
    func showCountryErrorView(){
        hideSpinner()
        showCountryErrorMessage {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func showCountryErrorMessage(completed: @escaping () -> ()){
        let title = "Delivery Not Available"
        let message = "Thred only supports delivery to all the Canadian provinces/territories except for British Columbia"
        let image = UIImage(named: "canada")
        let okBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        showPopUp(title: title, message: message, image: image, buttons: [okBtn], titleColor: .label)
    }
    
    func strikethroughShipping(){
        let linkWords = "Shipping"
        shippingAndTaxLbl.text = nil
        let guideLineText = "Shipping and Tax:"
        
        shippingAndTaxLbl.text = guideLineText
        let attrString = NSMutableAttributedString()
        if let text = shippingAndTaxLbl.attributedText{
            attrString.setAttributedString(text)
        }
        
        let nsText = NSString(string: guideLineText)
        let matchRange:NSRange = nsText.range(of: linkWords)
        
        guard let font = UIFont(name: "NexaW01-Regular", size: shippingAndTaxLbl.font?.pointSize ?? 16) else{return}
        
        let attributes = [
            NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.thick.rawValue,
            NSAttributedString.Key.strikethroughColor: UIColor.red,
            NSAttributedString.Key.font : font,
        ] as [NSAttributedString.Key : Any]
        
        attrString.addAttributes(attributes, range: matchRange)

        shippingAndTaxLbl.attributedText = attrString
    }
    
    func calculateCosts(province: String?, completed: @escaping () -> ()){
        
        
        guard let province = province else{showErrorView(); return}
        
        var subtotal = 0.00
        var productCount = 0
        
        for product in savedProducts{
            guard let price = product.product.price, let quantity = product.quantity else{continue}
            subtotal += price * Double(quantity)
            productCount += quantity
        }
        
        //let subtotal = savedProducts.compactMap({$0.product.price}).reduce(0, +)
        
        Firestore.firestore().collection("Canada_Tax_Docs").document(province).getDocument(completion: { doc, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                var salesTax = 0.0
                
                if let hst = doc?["HST"] as? Double{
                    salesTax += hst
                }
                else{
                    if let gst = doc?["GST"] as? Double{
                        salesTax += gst
                    }
                    if let pst = doc?["PST"] as? Double{
                        salesTax += pst
                    }
                }
                self.salesInfo["SalesTax"] = salesTax
                let tax = salesTax * subtotal
                var shipping = 0.00
                if productCount < 5{
                    shipping = (self.salesInfo["Shipping"] ?? 0) / 100
                }
                else{
                    self.strikethroughShipping()
                }
                self.subtotalField.text = "\((subtotal).formatPrice())"
                self.taxShippingField.text = "\((tax + shipping).formatPrice())"
                self.totalField.text = "\((subtotal + tax + shipping).formatPrice())"
                completed()
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        payBtn.layer.cornerRadius = payBtn.frame.height / 8
        payBtn.clipsToBounds = true
        priceBackgroundView.layer.cornerRadius = priceBackgroundView.frame.height / 8
        priceBackgroundView.clipsToBounds = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedProducts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchProductCell", for: indexPath) as? SearchProductTableViewCell
        guard self.savedProducts.indices.contains(indexPath.row) else{return cell!}
        let savedProduct = self.savedProducts[indexPath.row]
        guard let product = savedProduct.product, let uid = product.userInfo.uid else{return cell!}
        cell?.productImageView.image = nil
        cell?.priceLbl.text = nil
        cell?.likesLbl.text = nil
        cell?.productNameLbl.text = nil
        cell?.likesView.isHidden = true
        cell?.savedProduct = nil
        cell?.quantityField.isEnabled = false
        
        cell?.productImageView.backgroundColor = ColorCompatibility.secondarySystemBackground
        cell?.quantityView.isHidden = false
        cell?.sizingLbl.isHidden = false
        
        DispatchQueue(label: "explore").async {
            if let dp = cache.imageFromMemoryCache(forKey: "thumbnail_\(product.productID)"){
                DispatchQueue.main.async {
                    cell?.productImageView.image = dp
                }
            }
            else{
                DispatchQueue.main.async {
                    self.getProductImage(productID: product.productID, uid: uid)
                }
            }
        }
        cell?.productImageView.backgroundColor = UIColor(named: product.templateColor)
        cell?.productImageView.backgroundColor = UIColor(named: product.templateColor)
        cell?.productNameLbl.text = product.name
        cell?.savedProduct = savedProduct
        
        cell?.priceLbl.text = product.price?.formatPrice()
        cell?.sizingLbl.text = "Size: \(savedProduct.size ?? "M")"
        cell?.quantityField.text = "\(savedProduct.quantity ?? 0)"
        
        return cell!
    }
    
    var downloadingPictures = [String]()
    
    func getProductImage(productID: String, uid: String){
        if !self.downloadingPictures.contains(productID){
            self.downloadingPictures.append(productID)
            let refString = "Users/" + uid + "/" + "Products/" + productID + "/" + "thumbnail_\(productID)" + ".png"
            let ref = Storage.storage().reference().child(refString)
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
                                self.downloadingPictures.removeAll(where: {$0 == productID})
                                cache.storeImage(toMemory: image, forKey: "thumbnail_\(productID)")
                                for index in self.savedProducts.indices{
                                    if self.savedProducts[index].product.productID == productID{
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
    
    @IBAction func confirmPayment(_ sender: UIButton) {
        
        var products = [[String : Any]]()
        sender.isEnabled = false
        showSpinner()
        
        guard let tax = salesInfo["SalesTax"], let shipping = salesInfo["Shipping"], let userUID = userInfo.uid, let adminArea = area, let country = country
        else{
            sender.isEnabled = true
        return}
        
        navigationItem.hidesBackButton = true

        for saved in savedProducts{
            guard let product = saved.product, let price = product.price, let name = product.name, let uid = product.userInfo.uid, let quantity = saved.quantity, let size = saved.size else{continue}
            let key = "TS_\(NSUUID().uuidString)"
            products.append([
                "productID": product.productID,
                "amount": price * 100,
                "size": size,
                "name" : name,
                "uid" : uid,
                "quantity" : quantity,
                "idempotency" : key,
            ])
        }
        
        if products.isEmpty{
            sender.isEnabled = true
            return
        }
        
        let key = "SHP_\(NSUUID().uuidString)"
        let data = [
            "Products": products,
            "tax": tax,
            "shipping": shipping,
            "uid": userUID,
            "shipping_idempotency" : key,
            "area" : adminArea,
            "country" : country
        ] as [String : Any]

        Functions.functions().httpsCallable("createIntent").call(data, completion: { result, error in
            if let err = error{
                print(err.localizedDescription)
                self.navigationController?.popViewController(animated: true)
            }
            else{
                if let orderNumber = result?.data as? String{
                    self.orderNumber = orderNumber
                }
                self.performSegue(withIdentifier: "toFinish", sender: nil)
            }
        })
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? FinishedPurchaseVC{
            vc.orderNumber = orderNumber
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    

}

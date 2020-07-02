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
    @IBOutlet weak var addressSpinner: MapSpinnerView!
    @IBOutlet weak var addressSpinnerView: UIView!
    @IBOutlet weak var priceSpinner: MapSpinnerView!
    @IBOutlet weak var priceSpinnerView: UIView!
    @IBOutlet weak var shippingAndTaxLbl: UILabel!
    @IBOutlet weak var streetField: UILabel!
    @IBOutlet weak var cityField: UILabel!
    @IBOutlet weak var postalField: UILabel!
    @IBOutlet weak var changeBtn: UIButton!
    var province: String?
    
    @IBOutlet weak var addressBackgroundView: UIView!
    var orderNumber: String?
    
    var address = [String : String]()
    var giftAddress = [String : String]()

    var salesInfo = [
        "SalesTax" : 0.0,
        "Shipping" : 0.00
    ]
    
    @IBAction func addOrChangeAddress(_ sender: UIButton) {
        
        self.performSegue(withIdentifier: "toAddress", sender: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "SearchProductTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchProductCell")
        
        tableView.allowsSelection = false
        payBtn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        payBtn.isEnabled = false

        if let street = UserDefaults.standard.string(forKey: "street"), let city = UserDefaults.standard.string(forKey: "city"), let adminArea = UserDefaults.standard.string(forKey: "admin_area"), let country = UserDefaults.standard.string(forKey: "country"), UserDefaults.standard.string(forKey: "postal_code") != nil{
            let unitNum = UserDefaults.standard.string(forKey: "unit_number")
            getAddress(street: street, city: city, adminArea: adminArea, country: country, unitNum: unitNum)
        }
        else{
            setAddress()
        }
    }
    
    func getAddress(street: String, city: String, adminArea: String, country: String, unitNum: String?){
        showAddressSpinner()
        showPriceSpinner()
        
        if let postalCode = UserDefaults.standard.string(forKey: "CARD_POSTAL_CODE"){
            self.validateAddress(address: postalCode, completed: { country, adminArea, _, _, postalCode, isValid in
                
                self.province = adminArea
                self.setAddress()
                if country == "Canada", adminArea != "BC"{
                    self.hideAddressSpinner()
                    self.calculateCosts(province: adminArea){
                        self.hidePriceSpinner()
                        self.payBtn.isEnabled = true
                    }
                }
                else{
                    self.showCardCountryErrorView()
                }
            })
        }
        
        let address = "\(street), \(city), \(adminArea), \(country)"
        validateAddress(address: address, completed: { country, adminArea, city, street, postalCode, isValid in
            if isValid{
                if country == "Canada", adminArea != "BC"{
                    self.address["Area"] = adminArea
                    self.address["Country"] = country
                    self.address["City"] = city
                    self.address["Street"] = street
                    self.address["Postal"] = postalCode
                    
                    if let unitNum = unitNum, !unitNum.isEmpty{
                        self.address["Unit"] = unitNum
                    }
                    else{
                        self.address.removeValue(forKey: "Unit")
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
    
    
    
    func setAddress(){
        guard let adminArea = address["Area"], let country = address["Country"], let city = address["City"], let street = address["Street"], let postal = address["Postal"]
        else {
            streetField.text = "No delivery address set."
            cityField.text = nil
            postalField.text = nil
            
            changeBtn.titleLabel?.text = "Add"
            changeBtn.setTitle("Add", for: .normal)
            return
        }
        changeBtn.titleLabel?.text = "Change"
        changeBtn.setTitle("Change", for: .normal)
        streetField.text = "\(street)"
        if let unit = self.address["Unit"], !unit.isEmpty{
            streetField.text?.append(", Unit: \(unit)")
        }
        
        cityField.text = "\(city), \(adminArea). \(country)"
        postalField.text = "\(postal)"
    }
    
    func showPriceSpinner(){
        priceSpinnerView.isHidden = false
        priceSpinner.animate()
    }
    
    func hidePriceSpinner(){
        priceSpinnerView.isHidden = true
    }
    
    func showAddressSpinner(){
        addressSpinnerView.isHidden = false
        addressSpinner.animate()
    }
    
    func hideAddressSpinner(){
        addressSpinnerView.isHidden = true
    }
    

    func showErrorView(){
        
        hideAddressSpinner()
        hidePriceSpinner()
    }
    
    func showCountryErrorView(){
        hideAddressSpinner()
        showCountryErrorMessage {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func showCardCountryErrorView(){
        hideAddressSpinner()
        showCardCountryErrorMessage {
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
    
    func showCardCountryErrorMessage(completed: @escaping () -> ()){
        let title = "Purchasing Not Available"
        let message = "Thred only allows purchasing from all the Canadian provinces/territories except for British Columbia"
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
        
        for product in savedProducts{
            guard let price = product.product.price, let quantity = product.quantity else{continue}
            subtotal += price * Double(quantity)
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
                if self.savedProducts.compactMap({$0.quantity}).reduce(0, +) < 5{
                    shipping = 12.00
                    self.salesInfo["Shipping"] = 1200
                }
                else{
                    self.strikethroughShipping()
                    self.salesInfo["Shipping"] = 0.00
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
        addressBackgroundView.layer.cornerRadius = addressBackgroundView.frame.height / 8
        addressBackgroundView.clipsToBounds = true
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
        cell?.isDeleted = false
        
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
        cell?.isDeleted = !(product.isAvailable ?? false)

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
        showPriceSpinner()
                
        guard let tax = salesInfo["SalesTax"], let shipping = salesInfo["Shipping"], let userUID = userInfo.uid, let adminArea = address["Area"], let country = address["Country"], let city = address["City"], let street = address["Street"], let postal = address["Postal"]
        else{
            sender.isEnabled = true
        return}
        
        
        navigationItem.hidesBackButton = true
        
        var address = [
            "postal_code" : postal,
            "country" : country,
            "admin_area" : adminArea,
            "city" : city,
            "street_address" : street
        ]
        
        print(shipping)
        
        if let unit = self.address["Unit"], !unit.isEmpty{
            address["unit_number"] = unit
        }

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
            "totalQty": savedProducts.compactMap({$0.quantity}).reduce(0, +),
            "tax": tax,
            "shipping": shipping,
            "uid": userUID,
            "shipping_idempotency" : key,
            "area" : province ?? "none",
            "country" : country,
            "address" : address
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
        else if let addressVC = segue.destination as? AddressVC{
            addressVC.isGiftAddress = true
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    

}

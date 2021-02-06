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
import FirebaseFirestore

class SalesInfo{
    
    var shipping: Double = 0
    var tax: Double = 0
    var currency: String?
    var final: Double?
    
    var rate: Double = 1{
        didSet{
            shipping = shipping * rate
            tax = tax * rate
        }
    }
}

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
    @IBOutlet weak var nameField: UILabel!
    @IBOutlet weak var phoneNumField: UILabel!
    @IBOutlet weak var streetField: UILabel!
    @IBOutlet weak var cityField: UILabel!
    @IBOutlet weak var postalField: UILabel!
    @IBOutlet weak var changeBtn: UIButton!
    var billing_info = [String : String]()

    
    @IBOutlet weak var addressBackgroundView: UIView!
    var orderNumber: String?
    
    var address = [String : String]()
    var giftAddress = [String : String]()

    var salesInfo = SalesInfo()
    
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

        validateCosts{
            if let street = UserDefaults.standard.string(forKey: "street"), let city = UserDefaults.standard.string(forKey: "city"), let adminArea = UserDefaults.standard.string(forKey: "admin_area"), let country = UserDefaults.standard.string(forKey: "country"), UserDefaults.standard.string(forKey: "postal_code") != nil{
                let unitNum = UserDefaults.standard.string(forKey: "unit_number")
                let phoneNumber = UserDefaults.standard.string(forKey: "phone_number")
                var fullName: String?
                if let firstName = UserDefaults.standard.string(forKey: "first_name"), let lastName = UserDefaults.standard.string(forKey: "last_name"){
                    fullName = "\(firstName) \(lastName)"
                }
                self.getAddress(street: street, city: city, adminArea: adminArea, country: country, unitNum: unitNum, fullName: fullName, phoneNumber: phoneNumber)
            }
            else{
                self.setAddress()
            }
        }
    }
    
    func validateCosts(completed: @escaping () -> ()){
        if let postalCode = UserDefaults.standard.string(forKey: "CARD_POSTAL_CODE"){
            showPriceSpinner()
            self.validateAddress(address: postalCode, completed: { country, adminArea, city, street, postalCode, countryCode, isValid in
                self.billing_info["Admin_Area"] = adminArea
                self.billing_info["Country"] = country
                self.billing_info["Postal"] = postalCode
                self.billing_info["Street"] = street
                self.billing_info["City"] = city
                self.billing_info["CountryCode"] = countryCode
                self.hideAddressSpinner()
                completed()
            })
        }
    }
    
    func getAddress(street: String, city: String, adminArea: String, country: String, unitNum: String?, fullName: String?, phoneNumber: String?){
        showAddressSpinner()
                
        let address = "\(street), \(city), \(adminArea), \(country)"
        validateAddress(address: address, completed: { country, adminArea, city, street, postalCode, countryCode, isValid in
            switch isValid{
            case true:
                self.address["Area"] = adminArea
                self.address["Country"] = country
                self.address["City"] = city
                self.address["Street"] = street
                self.address["Postal"] = postalCode
                self.address["CountryCode"] = countryCode
                
                if let fullName = fullName, !fullName.isEmpty, let phoneNumber = phoneNumber, !phoneNumber.isEmpty{
                    self.address["Name"] = fullName
                    self.address["Phone"] = phoneNumber
                }
                
                if let unitNum = unitNum, !unitNum.isEmpty{
                    self.address["Unit"] = unitNum
                }
                else{
                    self.address.removeValue(forKey: "Unit")
                }
                self.setAddress()
                self.hideAddressSpinner()
                
                self.calculateCosts(shippingCountry: countryCode ?? "US", billingInfo: self.billing_info){
                    self.hidePriceSpinner()
                    self.payBtn.isEnabled = true
                }
                
            default:
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
        if let name = self.address["Name"], !name.isEmpty{
            nameField.text = name
        }
        else{
            nameField.text = "*"
        }
        if let phone = self.address["Phone"], !phone.isEmpty{
            phoneNumField.text = phone
        }
        else{
            phoneNumField.text = "*"
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
        showPopUp(title: title, message: message, image: image, buttons: [okBtn], titleColor: .label, blurBack: true)
    }
    
    func showCardCountryErrorMessage(completed: @escaping () -> ()){
        let title = "Purchasing Not Available"
        let message = "Thred only allows purchasing from all the Canadian provinces/territories except for British Columbia"
        let image = UIImage(named: "canada")
        let okBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        showPopUp(title: title, message: message, image: image, buttons: [okBtn], titleColor: .label, blurBack: true)
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
    
    func calculateSubtotal() -> Double{
        var subtotal = 0.00
        
        for product in savedProducts{
            guard let price = product.product.price, let quantity = product.quantity else{continue}
            subtotal += price * Double(quantity)
        }
        return subtotal
    }
    
    func calculateShipping(country: String, completed: @escaping (Double) -> ()){
        
        /*
        if savedProducts.compactMap({$0.quantity}).reduce(0, +) < 5{
            shipping = 12.00
            salesInfo["Shipping"] = 1200
        }
        else{
            strikethroughShipping()
            salesInfo["Shipping"] = 0.00
        }
         
 */
        Firestore.firestore().collection("Print_Info").document("Shipping_Info").getDocument(completion: { doc, error in
            
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                print(country)
                
                switch country{
                case "CA":
                    let shipping = doc?["shipping_rate_canada"] as? Double
                    self.salesInfo.shipping = (shipping ?? 12) * 100
                    completed(shipping ?? 12)
                default:
                    if doc?["Intl_Shipping"] as? Bool ?? false{
                        if country == "US" || country == "USA"{
                            print(country)
                            let shipping = doc?["shipping_rate_us"] as? Double
                            self.salesInfo.shipping = (shipping ?? 12) * 100
                            completed(shipping ?? 12)
                            
                        }
                        else{
                            print(country)
                            
                            self.showCardCountryErrorView()
                        }
                    }
                    else{
                        self.showCardCountryErrorView()
                    }
                }
            }
        })
    }
    
    func setPriceLabels(subtotal: Double, shipping: Double, tax: Double, currency: String, rate: Double, finalAmount: Double){
        subtotalField.text = "\((subtotal * rate).formatPrice(addCurrency: currency))"
        taxShippingField.text = "\((((tax) + shipping) * rate).formatPrice(addCurrency: currency))"
        totalField.text = "\(((subtotal + tax + shipping) * rate).formatPrice(addCurrency: currency))"
        
        shippingAndTaxLbl.text = "Shipping and Tax:"
        if shipping == 0 && tax == 0{
            shippingAndTaxLbl.superview?.isHidden = true
        }
        else if shipping == 0{
            shippingAndTaxLbl.text = "Tax:"
            shippingAndTaxLbl.superview?.isHidden = false
        }
        else if tax == 0{
            shippingAndTaxLbl.text = "Shipping:"
            shippingAndTaxLbl.superview?.isHidden = false
        }
    }

    func calculateCosts(shippingCountry: String, billingInfo: [String : String], completed: @escaping () -> ()){
                
        let subtotal = calculateSubtotal()
        
        calculateShipping(country: shippingCountry, completed: { shipping in
            
            let data = [
                "Country" : self.billing_info["CountryCode"] ?? "",
                "Admin_Area" : self.billing_info["Admin_Area"] ?? "",
                "Street" : self.billing_info["Street"] ?? "",
                "Postal" : self.billing_info["Postal"] ?? "",
                "City" : self.billing_info["City"] ?? "",
                "amount" : subtotal
                ] as [String : Any]
            
            Functions.functions().httpsCallable("calculateTax").call(data, completion: { result, error in
                
                if let err = error{
                    print(err.localizedDescription)
                    
                }
                else{
                    if let returnData = result?.data as? [String : Any]{
                        print(returnData)
                        
                        let currency = returnData["Currency"] as? String ?? "USD"
                        let tax = ((returnData["Tax"] as? Double ?? 0) * subtotal).roundToDecimal()
                        
                        let final_amount_converted = returnData["Final_Amount"] as? Double ?? 0
                        let rate = returnData["Rate"] as? Double ?? 1
                        
                        self.salesInfo.tax = tax
                        self.salesInfo.currency = currency
                        self.salesInfo.final = final_amount_converted
                        self.salesInfo.rate = rate
                        
                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: .fade)
                        }, completion: nil)
                        
                        self.setPriceLabels(subtotal: subtotal, shipping: shipping, tax: tax, currency: String(currency.shortenCurrency()), rate: rate, finalAmount: final_amount_converted)
                    }
                    completed()
                }
            })
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
        
        cell?.productImageView.backgroundColor = .secondarySystemBackground
        cell?.quantityView.isHidden = false
        cell?.sizingLbl.isHidden = false
        
        DispatchQueue(label: "explore").async {
            var prefix = ""
            if product.displaySide == "back" || product.displaySide == "Back"{
                prefix = "BACK_"
            }
            if let dp = cache.imageFromMemoryCache(forKey: "thumbnail_\(prefix)\(product.productID)"){
                DispatchQueue.main.async {
                    cell?.productImageView.image = dp
                }
            }
            else{
                DispatchQueue.main.async {
                    self.getProductImage(productID: product.productID, uid: uid, product: product)
                }
            }
        }
        
        let color = all.tees.first(where: {$0.productCode == product.productType})?.colors.first(where: {$0.code == product.templateColor})?.getColor()

        cell?.productImageView.backgroundColor = color
        cell?.productNameLbl.text = product.name
        cell?.isDeleted = !(product.isAvailable ?? false)

        cell?.savedProduct = savedProduct
        
        cell?.priceLbl.text = ((product.price ?? 0) * salesInfo.rate).formatPrice(addCurrency: String(salesInfo.currency?.shortenCurrency() ?? ""))
        cell?.sizingLbl.text = "Size: \(savedProduct.size ?? "M")"
        cell?.quantityField.text = "\(savedProduct.quantity ?? 0)"
        
        return cell!
    }
    
    var downloadingPictures = [String]()
    
    func getProductImage(productID: String, uid: String, product: Product?){
        if !self.downloadingPictures.contains(productID){
            self.downloadingPictures.append(productID)
            var prefix = ""
            if product?.displaySide == "back" || product?.displaySide == "Back"{
                prefix = "BACK_"
            }
            let refString = "Users/" + uid + "/" + "Products/" + productID + "/" + "thumbnail_\(prefix)\(productID)" + ".png"
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
                                cache.storeImage(toMemory: image, forKey: "thumbnail_\(prefix)\(productID)")
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
                
        guard let userUID = pUserInfo.uid, let adminArea = address["Area"], let country = address["Country"], let countryCode = address["CountryCode"], let city = address["City"], let street = address["Street"], let postal = address["Postal"]
        else{
            sender.isEnabled = true
        return}
        
        let tax = salesInfo.tax
        let shipping = salesInfo.shipping
        
        guard let phone = address["Phone"], let name = address["Name"] else{
            showNameMessage {
                self.navigationController?.popViewController(animated: true)
            }
            sender.isEnabled = true
            return
        }
        
        navigationItem.hidesBackButton = true
        
        var address = [
            "postal_code" : postal,
            "country" : country,
            "country_code" : countryCode,
            "admin_area" : adminArea,
            "city" : city,
            "street_address" : street,
            "phone_number" : phone,
            "full_name" : name
        ]
        
        print(shipping)
        
        if let unit = self.address["Unit"], !unit.isEmpty{
            address["unit_number"] = unit
        }

        for saved in savedProducts{
            guard let product = saved.product, let price = product.price, let name = product.name, let uid = product.userInfo.uid, let quantity = saved.quantity, let size = saved.size else{continue}
            let productType = product.productType ?? defaultProductType
            let key = "TS_\(NSUUID().uuidString)"
            products.append([
                "productID": product.productID,
                "amount": (price * 100) * self.salesInfo.rate,
                "size": size,
                "name" : name,
                "uid" : uid,
                "quantity" : quantity,
                "type" : productType,
                "idempotency" : key
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
            "area" : self.billing_info["Admin_Area"] ?? "none",
            "country" : country,
            "country_code" : self.billing_info["CountryCode"] ?? "",
            "address" : address,
            "currency" : salesInfo.currency?.lowercased() ?? "usd",
            "rate" : salesInfo.rate
        ] as [String : Any]

        Functions.functions().httpsCallable("createIntent").call(data, completion: { result, error in
            if let err = error{
                print(err.localizedDescription)
                self.navigationItem.hidesBackButton = false
                self.hidePriceSpinner()
                sender.isEnabled = true
                self.showPaymentErrorMessage(message: err.localizedDescription, completed: {
                    self.navigationController?.popViewController(animated: true)
                })
            }
            else{
                if let orderNumber = result?.data as? String{
                    self.orderNumber = orderNumber
                }
                self.performSegue(withIdentifier: "toFinish", sender: nil)
            }
        })
    }
    
    func showPaymentErrorMessage(message: String, completed: @escaping () -> ()){
        let title = "Error Processing Payment!"
        let okBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        showPopUp(title: title, message: message, image: nil, buttons: [okBtn], titleColor: .red, blurBack: true)
    }
    
    func showNameMessage(completed: @escaping () -> ()){
        let title = "Delivery Information Incomplete"
        let message = "Please update your delivery info under 'Home Address' in account settings"
        let okBtn = DefaultButton(title: "OK", dismissOnTap: true) {
            completed()
        }
        
        showPopUp(title: title, message: message, image: nil, buttons: [okBtn], titleColor: .red, blurBack: true)
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

extension String {
    public func toPhoneNumber() -> String {
        return self.replacingOccurrences(of: "(\\d{3})(\\d{3})(\\d+)", with: "$1-$2-$3", options: .regularExpression, range: nil)
    }
}

extension String{
    func shortenCurrency() -> String{
        return String(dropLast()).uppercased()
    }
}

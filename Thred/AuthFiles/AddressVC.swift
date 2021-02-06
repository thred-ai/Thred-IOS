//
//  AddressVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-06-01.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import CoreLocation
import Firebase
import FirebaseFirestore

class AddressVC: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var streetField: UITextField!
    @IBOutlet weak var cityField: UITextField!
    @IBOutlet weak var provinceField: UITextField!
    @IBOutlet weak var countryField: UITextField!
    @IBOutlet weak var postalCodeField: UITextField!
    @IBOutlet weak var nextBtn: UIBarButtonItem!
    @IBOutlet weak var unitField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var firstField: UITextField!
    @IBOutlet weak var lastField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    
    
    @IBOutlet weak var removeBtn: UIButton!
    
    @IBOutlet weak var errorView: UITextView!
    
    var isGiftAddress = false
    @IBOutlet weak var subtitleLbl: UITextView!
    
    var address = [String : String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
        
        streetField.inputAccessoryView = toolBar
        cityField.inputAccessoryView = toolBar
        provinceField.inputAccessoryView = toolBar
        countryField.inputAccessoryView = toolBar
        postalCodeField.inputAccessoryView = toolBar
        unitField.inputAccessoryView = toolBar
        firstField.inputAccessoryView = toolBar
        lastField.inputAccessoryView = toolBar
        phoneField.inputAccessoryView = toolBar
        errorView.text = nil
        
        if isGiftAddress && hasAddress(){
            
            subtitleLbl.text = "This address will be used for this order ONLY"
            subtitleLbl.textColor = UIColor(named: "LoadingColor")
            removeBtn.isEnabled = false
            removeBtn.isHidden = true
        }
        else{
            getFromFirestore(completed: { hasAddress in
                if hasAddress{
                    self.setExistingAddress()
                }
                else{
                    self.removeExistingAddress()
                    self.setExistingAddress()
                }
            })
        }
        // Do any additional setup after loading the view.
    }
    
    func removeExistingAddress(){
        UserDefaults.standard.removeObject(forKey: "street")
        UserDefaults.standard.removeObject(forKey: "city")
        UserDefaults.standard.removeObject(forKey: "admin_area")
        UserDefaults.standard.removeObject(forKey: "unit_number")
        UserDefaults.standard.removeObject(forKey: "postal_code")
        UserDefaults.standard.removeObject(forKey: "first_name")
        UserDefaults.standard.removeObject(forKey: "last_name")
        UserDefaults.standard.removeObject(forKey: "phone_number")

    }
    
    func hasAddress() -> Bool{
        let street = UserDefaults.standard.string(forKey: "street")
        let city = UserDefaults.standard.string(forKey: "city")
        let adminArea = UserDefaults.standard.string(forKey: "admin_area")
        let country = UserDefaults.standard.string(forKey: "country")
        let postalCode = UserDefaults.standard.string(forKey: "postal_code")
        let firstName = UserDefaults.standard.string(forKey: "first_name")
        let lastName = UserDefaults.standard.string(forKey: "last_name")
        let phoneNumber = UserDefaults.standard.string(forKey: "phone_number")
        
        return street != nil && city != nil && adminArea != nil && country != nil && postalCode != nil && firstName != nil && lastName != nil && phoneNumber != nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        hideCenterBtn()
        if !isGiftAddress{
            setExistingAddress()
        }
        setKeyBoardNotifs()
    }
    
    func setErrorView(_ text: String){
        errorView.text = text
    }
    
    func setExistingAddress(){
        let street = UserDefaults.standard.string(forKey: "street")
        let city = UserDefaults.standard.string(forKey: "city")
        let adminArea = UserDefaults.standard.string(forKey: "admin_area")
        let country = UserDefaults.standard.string(forKey: "country")
        let postalCode = UserDefaults.standard.string(forKey: "postal_code")
        let unitNumber = UserDefaults.standard.string(forKey: "unit_number")
        let firstName = UserDefaults.standard.string(forKey: "first_name")
        let lastName = UserDefaults.standard.string(forKey: "last_name")
        let phoneNumber = UserDefaults.standard.string(forKey: "phone_number")
            
        streetField.text = street
        cityField.text = city
        provinceField.text = adminArea
        countryField.text = country
        postalCodeField.text = postalCode
        unitField.text = unitNumber
        firstField.text = firstName
        lastField.text = lastName
        phoneField.text = phoneNumber
        
    }
    
    func setInFirestore(street: String, city: String, adminArea: String, country: String, postalCode: String, unitNumber: String?, firstName: String, lastName: String, phoneNumber: String){
        guard let uid = pUserInfo.uid else{return}
        
        var data = [
            "Street" : street,
            "City" : city,
            "Administrative_Area" : adminArea,
            "Country" : country,
            "Postal_Code" : postalCode,
            "First_Name" : firstName,
            "Last_Name" : lastName,
            "Phone_Num" : phoneNumber
        ]
        
        if let num = unitNumber{
            data["Unit_Number"] = num
        }
        
        Firestore.firestore().collection("Users/\(uid)/Payment_Info").document("Delivery_Address").setData(data, completion: { error in
            if let err = error{
                print(err.localizedDescription)
                self.setErrorView("Unable to update information")
            }
            else{
                self.setNewAddress(street: street, city: city, adminArea: adminArea, country: country, postalCode: postalCode, unitNumber: unitNumber, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber)
                
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    lazy var toolBar: UIView = {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 45))
        bar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        let stackView = UIStackView(frame: bar.frame)
        bar.addSubview(stackView)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(doneEditing(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        
        return bar
    }()
    
    
    
    @objc func doneEditing(_ sender: UIButton){
        streetField.resignFirstResponder()
        cityField.resignFirstResponder()
        provinceField.resignFirstResponder()
        countryField.resignFirstResponder()
        postalCodeField.resignFirstResponder()
        unitField.resignFirstResponder()
        firstField.resignFirstResponder()
        lastField.resignFirstResponder()
        phoneField.resignFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
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
                    if self.scrollView.contentInset.bottom == 0{
                        self.scrollView.contentOffset.y -= keyboardHeight - bottomPadding
                    }
                    self.scrollView.contentInset.bottom = keyboardHeight - bottomPadding
                    self.scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
                }, completion: { finished in
                    if finished{}
                })
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            UIView.animate(withDuration: 0.2, animations: {
                self.scrollView.contentInset.bottom = 0
                self.scrollView.verticalScrollIndicatorInsets.bottom = 0
            })
        }
    }
    @IBAction func removeAddress(_ sender: UIButton) {
        sender.isEnabled = false
        guard let uid = pUserInfo.uid else{return}
        Firestore.firestore().collection("Users/\(uid)/Payment_Info").document("Delivery_Address").delete(completion: { error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                UserDefaults.standard.removeObject(forKey: "street")
                UserDefaults.standard.removeObject(forKey: "city")
                UserDefaults.standard.removeObject(forKey: "admin_area")
                UserDefaults.standard.removeObject(forKey: "country")
                UserDefaults.standard.removeObject(forKey: "postal_code")
                UserDefaults.standard.removeObject(forKey: "unit_number")
            }
            self.navigationController?.popViewController(animated: true)
        })
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let vc = viewController as? CheckoutVC{
            guard
                let adminArea = address["Area"],
                let country = address["Country"],
                let city = address["City"],
                let street = address["Street"],
                let name = address["Name"],
                let phone = address["Phone"]
            else { return }
            let unit = address["Unit"]
            vc.getAddress(street: street, city: city, adminArea: adminArea, country: country, unitNum: unit, fullName: name, phoneNumber: phone)
        }
    }
    
    @IBAction func nextBtnPressed(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        errorView.text = nil
        
        guard let street = self.streetField.text, let adminArea = self.provinceField.text, let city = self.cityField.text, let country = self.countryField.text, let firstName = self.firstField.text, !firstName.isEmpty, let lastName = self.lastField.text, !lastName.isEmpty, let phoneNumber = self.phoneField.text?.toPhoneNumber(), !phoneNumber.isEmpty, self.postalCodeField.text != nil else {
            self.setErrorView("1 or more fields empty")
            sender.isEnabled = true
            return
        }
        
        let address = "\(street), \(city), \(adminArea), \(country)"
        let unitNumber = self.unitField.text
        
        self.validateAddress(address: address, completed: { country, adminArea, city, street, postalCode, countryCode, isValid in
            sender.isEnabled = true
            if isValid{
                guard let street = street, let country = country, let adminArea = adminArea, let postalCode = postalCode, let city = city else{return}
                if country != "Canada"{
                    
                }
                switch self.isGiftAddress{
                    
                case true:
                    self.address = [
                        "Country": country,
                        "City": city,
                        "Area": adminArea,
                        "Postal": postalCode,
                        "Street": street,
                        "Name" : "\(firstName) \(lastName)",
                        "Phone": phoneNumber
                    ]
                    if self.hasAddress(){
                        
                        if let unitNum = unitNumber, !unitNum.isEmpty{
                            self.address["Unit"] = unitNum
                        }
                        self.navigationController?.popViewController(animated: true)
                    }
                    else{
                        fallthrough
                    }
                default:
                    self.setInFirestore(street: street, city: city, adminArea: adminArea, country: country, postalCode: postalCode, unitNumber: unitNumber, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber)
                }
            }
            else{
                self.setErrorView("This delivery address is invalid")
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        streetField.layer.cornerRadius = streetField.frame.height / 4
        streetField.clipsToBounds = true
        cityField.layer.cornerRadius = cityField.frame.height / 4
        cityField.clipsToBounds = true
        provinceField.layer.cornerRadius = provinceField.frame.height / 4
        provinceField.clipsToBounds = true
        countryField.layer.cornerRadius = countryField.frame.height / 4
        countryField.clipsToBounds = true
        postalCodeField.layer.cornerRadius = postalCodeField.frame.height / 4
        postalCodeField.clipsToBounds = true
        unitField.layer.cornerRadius = unitField.frame.height / 4
        unitField.clipsToBounds = true
        firstField.layer.cornerRadius = firstField.frame.height / 4
        firstField.clipsToBounds = true
        lastField.layer.cornerRadius = lastField.frame.height / 4
        lastField.clipsToBounds = true
        
        phoneField.layer.cornerRadius = phoneField.frame.height / 4
        phoneField.clipsToBounds = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIViewController{
    func getFromFirestore(completed: @escaping (Bool) -> ()){
        guard let uid = pUserInfo.uid else{return}

        Firestore.firestore().collection("Users/\(uid)/Payment_Info").document("Delivery_Address").getDocument(completion: { document, error in
            
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                guard let document = document, document.exists, let street = document["Street"] as? String, let city = document["City"] as? String, let adminArea = document["Administrative_Area"] as? String, let country = document["Country"] as? String, let postalCode = document["Postal_Code"] as? String
                    else{
                        completed(false)
                    return}
                let firstName = document["First_Name"] as? String ?? ""
                let lastName = document["Last_Name"] as? String ?? ""
                let phoneNumber = document["Phone_Num"] as? String ?? ""
                let unitNumber = document["Unit_Number"] as? String
                
                self.setNewAddress(street: street, city: city, adminArea: adminArea, country: country, postalCode: postalCode, unitNumber: unitNumber, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber)
                completed(true)
            }
        })
    }
    
    func setNewAddress(street: String, city: String, adminArea: String, country: String, postalCode: String, unitNumber: String?, firstName: String, lastName: String, phoneNumber: String){
        
        UserDefaults.standard.set(street, forKey: "street")
        UserDefaults.standard.set(city, forKey: "city")
        UserDefaults.standard.set(adminArea, forKey: "admin_area")
        UserDefaults.standard.set(country, forKey: "country")
        UserDefaults.standard.set(postalCode, forKey: "postal_code")
        UserDefaults.standard.set(firstName, forKey: "first_name")
        UserDefaults.standard.set(lastName, forKey: "last_name")
        UserDefaults.standard.set(phoneNumber, forKey: "phone_number")

        if let num = unitNumber{
            UserDefaults.standard.set(num, forKey: "unit_number")
        }
        else{
            UserDefaults.standard.removeObject(forKey: "unit_number")
        }
    }
    
    func validateAddress(address: String, completed: @escaping (String?, String?, String?, String?, String?, String?, Bool) -> ()){
        CLGeocoder().geocodeAddressString(address) { (placemarks, error) in
            if let error = error{
                print("Unable to get the location: (\(error))")
                completed(nil, nil, nil, nil, nil, nil, false)
            }
            else{
                if let placemarks = placemarks{

                    if let country = placemarks.first?.country, let province = placemarks.first?.administrativeArea, let number = placemarks.first?.subThoroughfare, let streetName = placemarks.first?.thoroughfare, let city = placemarks.first?.locality, let postalCode = placemarks.first?.postalCode, let countryCode = placemarks.first?.isoCountryCode{
                        print("country: -> \(country)")
                        print("administrative area: -> \(province)")
                        let street = "\(number) \(streetName)"
                        completed(country, province, city, street, postalCode, countryCode, true)
                    }
                    else{
                        if let province = placemarks.first?.administrativeArea, let country = placemarks.first?.country, let postalCode = placemarks.first?.postalCode, let countryCode = placemarks.first?.isoCountryCode{
                            completed(country, province, nil, nil, postalCode, countryCode, true)
                        }
                        else{
                            completed(nil, nil, nil, nil, nil, nil, false)
                        }
                    }
                }
                else{
                    completed(nil, nil, nil, nil, nil, nil, false)
                }
            }
        }
    }
}


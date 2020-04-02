//
//  PhoneAuthViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-05-21.
//  Copyright © 2018 ARTACORP. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SwiftKeychainWrapper
import ColorCompatibility

struct Country: Decodable{
    
    let name: String
    let dial_code: String
    let code: String
    let flag: String
}


class PhoneAuthViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    let countryDisplay = UIPickerView()
    @IBOutlet weak var sendCodeBtn: UIBarButtonItem!
    @IBOutlet weak var codeDisplay: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var termsOfServiceView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var errorView: UITextView!
    
    var countries = [Country]()
    var code: String = ""
    var verificationid: String = ""
    var phoneNum = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        codeDisplay.inputView = countryDisplay
        let locale = Locale.current
        print(locale.regionCode ?? "N/A")
        countryDisplay.delegate = self
        countryDisplay.dataSource = self
        phoneNumber.inputAccessoryView = toolBar
        codeDisplay.inputAccessoryView = toolBar
        let path = Bundle.main.path(forResource: "countries", ofType: "json")
        let url = URL(fileURLWithPath: path!)
        do {
            let data = try Data(contentsOf: url)
            self.countries = try JSONDecoder().decode([Country].self, from: data)
        }
        catch{}
        for currentCountry in countries{
            if(currentCountry.code == locale.regionCode){
                print(currentCountry.dial_code)
                codeDisplay.text = currentCountry.code + " " + currentCountry.dial_code + " " + currentCountry.flag
                code = currentCountry.dial_code
            }
        }
        DispatchQueue.main.async {
            self.countryDisplay.reloadComponent(0)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    lazy var toolBar: UIView = {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 45))
        bar.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.8)
        let stackView = UIStackView(frame: bar.frame)
        bar.addSubview(stackView)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        button.setTitle("Done", for: .normal)
        button.setTitleColor(ColorCompatibility.label, for: .normal)
        button.addTarget(self, action: #selector(doneEditing(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        
        return bar
    }()
    
    @objc func doneEditing(_ sender: UIButton){
        codeDisplay.resignFirstResponder()
        phoneNumber.resignFirstResponder()
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
    
    
    
    override func viewDidLayoutSubviews() {
        codeDisplay.layer.cornerRadius = codeDisplay.frame.height / 2
        phoneNumber.layer.cornerRadius = phoneNumber.frame.height / 2
        codeDisplay.clipsToBounds = true
        phoneNumber.clipsToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if KeychainWrapper.standard.string(forKey: "PHONE_NUM")  == nil{
            phoneNumber.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        setKeyBoardNotifs()

        if let num = KeychainWrapper.standard.string(forKey: "PHONE_NUM"){
            let newString = num.replacingOccurrences(of: code, with: "", options: .literal, range: nil)
            phoneNumber.text = newString
        }
        else{
           
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        
        return countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return countries[row].flag + " " + countries[row].name + " " + countries[row].dial_code
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        codeDisplay.text = countries[row].code + " " + countries[row].dial_code + " " + countries[row].flag
        code = countries[row].dial_code
    }
    
    @IBAction func sendCode(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        let phoneNumber = code + self.phoneNumber.text!
        phoneNum = phoneNumber.stripped
        Auth.auth().languageCode = "en";
        print(phoneNum)
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNum, uiDelegate: nil) { (verificationID, error) in
            if let err = error {
                print(err.localizedDescription)
                self.errorView.text = err.localizedDescription
                self.errorView.textColor = .systemRed
                sender.isEnabled = true
                return
            }
            else{
                self.errorView.text = nil
                self.performSegue(withIdentifier: "toCode", sender: nil)
                UserDefaults.standard.set(verificationID, forKey: "VerificationID")
                print("SMS Sent")
                sender.isEnabled = true
            }
        }
    }
    
    @IBAction func unwindToViewController(segue:  UIStoryboardSegue) {
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Create a variable that you want to send
        let vc = segue.destination as? CodeViewController
        vc?.phoneNumber = phoneNum
    }
}







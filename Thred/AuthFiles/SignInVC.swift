//
//  SignInVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import Firebase
import CryptoSwift

class SignInVC: UIViewController {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func signIn(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        guard let text = passwordField.text
        else{
            sender.isEnabled = true
            return
        }
        
        guard let usernameOrEmail = usernameField.text
        else{
            sender.isEnabled = true
            return
                
        }
        let fieldToSearch = "Username"
        
        
        let data = [
            "Code" : text,
            "Field" : fieldToSearch,
            "Term" : usernameOrEmail
        ]
        
        self.errorView.text = nil
        let spinner = MapSpinnerView.init(frame: CGRect(x: 5, y: 5, width: imageView.frame.height, height: imageView.frame.height))
        spinner.center = imageView.center
        imageView.addSubview(spinner)
        spinner.animate()
        
        if usernameOrEmail.contains("@"){
            sender.isEnabled = true
            self.signIn(email: usernameOrEmail, password: text, spinner: spinner)
        }
        else{
            Functions.functions().httpsCallable("auth").call(data, completion: { result, error in
                if let err = error{
                    spinner.removeFromSuperview()
                    self.updateErrorView(text: err.localizedDescription)
                    print(err.localizedDescription)
                    sender.isEnabled = true
                }
                else{
                    sender.isEnabled = true
                    guard let result = result else{return}
                    guard let returnedString = result.data as? String else{return}
                    if returnedString.starts(with: "ERROR:"){
                        spinner.removeFromSuperview()
                        let err = returnedString.replacingOccurrences(of: "ERROR:", with: "")
                        print(err)
                        self.updateErrorView(text: err)
                    }
                    else{
                        self.signIn(email: returnedString, password: text, spinner: spinner)
                    }
                }
            })
        }
    }
    
    func signIn(email: String, password: String, spinner: MapSpinnerView){
        Auth.auth().signIn(withEmail: email, password: password, completion: { result, error in
            if let err = error{
                spinner.removeFromSuperview()
                self.updateErrorView(text: "Invalid Password")
                print(err.localizedDescription)
            }
            else{
                guard let userUID = Auth.auth().currentUser?.uid else{
                    return}
                UserDefaults.standard.set(userUID, forKey: "UID")
                userInfo.uid = userUID
                self.loadUser(userUID: userUID){ success in
                    if success{
                        if let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate{
                            appdelegate.registerNotifs(application: UIApplication.shared)
                            self.performSegue(withIdentifier: "toProfile", sender: nil)
                        }
                    }
                    else{
                        self.performSegue(withIdentifier: "toAccountSetup", sender: nil)
                    }
                }
            }
        })
    }
    
    func updateErrorView(text: String){
        errorView.textColor = .systemRed
        errorView.text = text
    }
    
    @IBAction func toSignUp(_ sender: UIButton) {
        
        if navigationController?.viewControllers.contains(where: {$0.isKind(of: SignUpVC.self)}) ?? false{
            navigationController?.popViewController(animated: true)
        }
        else{
            performSegue(withIdentifier: "toSignUp", sender: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        usernameField.layer.cornerRadius = usernameField.frame.height / 2
        usernameField.clipsToBounds = true
        
        passwordField.layer.cornerRadius = passwordField.frame.height / 2
        passwordField.clipsToBounds = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameField.inputAccessoryView = toolBar
        passwordField.inputAccessoryView = toolBar

    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        setKeyBoardNotifs()
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
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension String{
    func encrypt() -> String?  {
        if let aes = try? AES(key: "passwordpassword", iv: "drowssapdrowssap"),
           let encrypted = try? aes.encrypt(Array(self.utf8)) {
            return encrypted.toHexString()
        }
        return nil
    }
    
    func decrypt() -> String? {
        if let aes = try? AES(key: "passwordpassword", iv: "drowssapdrowssap"),
            let decrypted = try? aes.decrypt(Array<UInt8>(hex: self)) {
            return String(data: Data(decrypted), encoding: .utf8)
        }
        return nil
    }
}

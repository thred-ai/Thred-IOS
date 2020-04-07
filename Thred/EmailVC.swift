//
//  EmailVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-01.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import ColorCompatibility

class EmailVC: UIViewController {

    @IBOutlet weak var emailView: UITextField!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        emailView.inputAccessoryView = toolBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        emailView.becomeFirstResponder()
        
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
        emailView.resignFirstResponder()
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
        emailView.layer.cornerRadius = emailView.frame.height  / 2
        emailView.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setKeyBoardNotifs()
        if let email = UserDefaults.standard.string(forKey: "EMAIL"){
            emailView.text = email
        }
    }
    
    @IBAction func addEmail(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        guard let text = emailView.text, !text.isEmpty, text.filter({$0 == "@"}).count == 1 else{
            updateErrorView(text: "Not a valid email")
            sender.isEnabled = true
            return}
        guard let uid = UserDefaults.standard.string(forKey: "UID") else{
            sender.isEnabled = true
            return}
        errorView.text = nil
        
        let link = URL(string: "https://thred.page.link/eNh4")
        
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = link
        // The sign-in operation has to always be completed in the app.
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        actionCodeSettings.setAndroidPackageName("com.example.android",
                                                 installIfNotAvailable: false, minimumVersion: "12")
        
        
        checkAuthStatus {
            
            Auth.auth().sendSignInLink(toEmail: text, actionCodeSettings: actionCodeSettings, completion: { error in
                
                if let err = error {
                    self.updateErrorView(text: err.localizedDescription)
                    sender.isEnabled = true
                  return
                }
               
                else{
                    self.errorView.text = nil
                    Firestore.firestore().collection("Users").document(uid).updateData(["Email" : text], completion: { error in
                        
                        if error != nil{
                            sender.isEnabled = true
                        }
                        else{
                            if UserDefaults.standard.string(forKey: "EMAIL") != nil, UserDefaults.standard.string(forKey: "USERNAME") != nil{
                                UserDefaults.standard.set(text, forKey: "EMAIL")
                                self.performSegue(withIdentifier: "UnwindToSettings", sender: nil)
                            }
                            else{
                                UserDefaults.standard.set(text, forKey: "EMAIL")
                                self.performSegue(withIdentifier: "toAccountSetup", sender: nil)
                            }
                            sender.isEnabled = true
                        }
                    })
                }
            })
        }
    }
    
    @IBAction func skipEmail(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toAccountSetup", sender: nil)
    }
    
    func updateErrorView(text: String){
        errorView.textColor = .systemRed
        errorView.text = text
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

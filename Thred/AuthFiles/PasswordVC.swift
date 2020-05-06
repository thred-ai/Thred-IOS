//
//  PasswordVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import ColorCompatibility

class PasswordVC: UIViewController {
    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var signUpBtn: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var emailToUse: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        passwordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        signUpBtn.isEnabled = false
        passwordField.inputAccessoryView = toolBar
        confirmField.inputAccessoryView = toolBar
    }
    
    override func viewDidLayoutSubviews() {
        confirmField.layer.cornerRadius = confirmField.frame.height / 2
        confirmField.clipsToBounds = true
        
        passwordField.layer.cornerRadius = passwordField.frame.height / 2
        passwordField.clipsToBounds = true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        if textField.text?.count ?? 0 < 6{
            updateErrorView(text: "Password must be at least 6 characters")
            signUpBtn.isEnabled = false
        }
        else{
            updateErrorView(text: nil)
            signUpBtn.isEnabled = true
        }
    }
    
    @IBAction func toAccountSetup(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        if passwordField.text != confirmField.text{
            updateErrorView(text: "Passwords do not match.")
            sender.isEnabled = true
            return
        }
        guard let password = passwordField.text else{
            sender.isEnabled = true
            return}
        
        if let user = Auth.auth().currentUser{
            let data = [
                "UID" : user.uid,
                "email" : emailToUse,
                "password" : password
            ]
            Functions.functions().httpsCallable("updateAuth").call(data, completion: { result, error in
                if let err = error{
                    print(err.localizedDescription)
                    sender.isEnabled = true
                    self.updateErrorView(text: "Error updating Auth info")
                }
                else{
                    do{
                        try Auth.auth().signOut()
                        let credential = EmailAuthProvider.credential(withEmail: self.emailToUse, password: password)
                        Auth.auth().signIn(with: credential, completion: { result, error in
                            if let err = error{
                                sender.isEnabled = true
                                print(err.localizedDescription)
                                UIApplication.shared.logout(withMessage: "Sign in with your new login credentials", segueToFirstScreen: true)
                            }
                            else{
                                sender.isEnabled = true
                                result?.user.sendEmailVerification(with: actionCodeSettings, completion: { error in
                                    if let err = error{
                                        sender.isEnabled = true
                                        print(err.localizedDescription)
                                        
                                    }
                                    else{
                                        if let userVC = self.navigationController?.viewControllers.first(where: {$0.isKind(of: UserVC.self)}){
                                            sender.isEnabled = true
                                            self.navigationController?.popToViewController(userVC, animated: true)
                                        }
                                    }
                                })
                            }
                        })
                    }catch{
                        print(error.localizedDescription)
                    }
                }
            })
        }
        else{
            Auth.auth().createUser(withEmail: emailToUse, password: password, completion: { result, error in
                if let err = error{
                    sender.isEnabled = true
                    self.updateErrorView(text: err.localizedDescription)
                }
                else{
                    if let user = result?.user{
                        UserDefaults.standard.set(user.email, forKey: "EMAIL")
                        UserDefaults.standard.set(user.uid, forKey: "UID")
                        user.sendEmailVerification(with: actionCodeSettings, completion: { error in
                            if let err = error{
                                sender.isEnabled = true
                                print(err.localizedDescription)
                            }
                            else{
                                
                            }
                        })
                        sender.isEnabled = true
                        self.performSegue(withIdentifier: "toAccountSetup", sender: nil)
                    }
                    else{
                        sender.isEnabled = true
                    }
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        confirmField.resignFirstResponder()
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
    
    
    
    func updateErrorView(text: String?){
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

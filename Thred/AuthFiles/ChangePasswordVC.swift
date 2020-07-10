//
//  ChangePasswordVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-16.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import ColorCompatibility

class ChangePasswordVC: UIViewController {
    @IBOutlet weak var currentField: UITextField!
    @IBOutlet weak var passField: UITextField!
    
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var updateBtn: UIBarButtonItem!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        passField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        updateBtn.isEnabled = false
        
        passField.inputAccessoryView = toolBar
        confirmField.inputAccessoryView = toolBar
        currentField.inputAccessoryView = toolBar
    }
    
    override func viewDidLayoutSubviews() {
        confirmField.layer.cornerRadius = confirmField.frame.height / 2
        confirmField.clipsToBounds = true
        
        passField.layer.cornerRadius = passField.frame.height / 2
        passField.clipsToBounds = true
        
        currentField.layer.cornerRadius = currentField.frame.height / 2
        currentField.clipsToBounds = true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        if textField.text?.count ?? 0 < 6{
            updateErrorView(text: "Password must be at least 6 characters")
            updateBtn.isEnabled = false
        }
        else{
            updateErrorView(text: nil)
            updateBtn.isEnabled = true
        }
    }
    
    @IBAction func finishPasswordChange(_ sender: UIBarButtonItem) {
        sender.isEnabled = false

        if passField.text != confirmField.text{
            updateErrorView(text: "Passwords do not match.")
            sender.isEnabled = true
            return
        }
        guard let password = passField.text else{
            sender.isEnabled = true
            return}
        guard let oldPassword = currentField.text else{
            sender.isEnabled = true
            return}
        
        if let user = Auth.auth().currentUser, let email = user.email{
            
            let authCredential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
            
            Auth.auth().currentUser?.reauthenticate(with: authCredential, completion: { result, error in
                if let err = error{
                    self.updateErrorView(text: "Incorrect password")
                    sender.isEnabled = true
                    print(err.localizedDescription)
                }
                else{
                    result?.user.updatePassword(to: password, completion: { error in
                        if let err = error{
                            self.updateErrorView(text: "Error changing password")
                            sender.isEnabled = true
                            print(err.localizedDescription)
                        }
                        else{
                            do{
                                try Auth.auth().signOut()
                                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                                Auth.auth().signIn(with: credential, completion: { result, error in
                                    if let err = error{
                                        print(err.localizedDescription)
                                        sender.isEnabled = true
                                    }
                                    else{
                                        sender.isEnabled = true
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                })
                            }catch{print(error.localizedDescription)}
                        }
                    })
                }
            })
        }
        else{
            sender.isEnabled = true
            self.updateErrorView(text: "Error changing password")
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
        currentField.resignFirstResponder()
        passField.resignFirstResponder()
        confirmField.resignFirstResponder()
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

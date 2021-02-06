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
import FirebaseFirestore

class PasswordVC: UIViewController {
    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var emailToUse: String!
    
    func checkIfNext(sender: UIButton){
        
        if passwordField.text?.isEmpty ?? false{
            confirmField.resignFirstResponder()
            passwordField.becomeFirstResponder()
        }
        else if confirmField.text?.isEmpty ?? false{
            passwordField.resignFirstResponder()
            confirmField.becomeFirstResponder()
        }
        else{
            confirmField.resignFirstResponder()
            passwordField.resignFirstResponder()
            toAccountSetup(sender)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        passwordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
        }
        else{
            updateErrorView(text: nil)
        }
    }
    
    func toAccountSetup(_ sender: UIButton) {
        
        sender.isEnabled = false
        if passwordField.text != confirmField.text{
            updateErrorView(text: "Passwords do not match.")
            sender.isEnabled = true
            return
        }
        guard let password = passwordField.text else{
            sender.isEnabled = true
            return}
        
        let spinner = MapSpinnerView.init(frame: CGRect(x: 5, y: 0, width: 20, height: 20))
        spinner.center.x = errorView.center.x
        errorView.addSubview(spinner)
        spinner.animate()
        
        Auth.auth().createUser(withEmail: emailToUse, password: password, completion: { result, error in
            if let err = error{
                sender.isEnabled = true
                spinner.removeFromSuperview()
                self.updateErrorView(text: err.localizedDescription)
            }
            else{
                Analytics.logEvent(AnalyticsEventSignUp, parameters: [
                    AnalyticsParameterMethod: self.method
                ])
                if let user = result?.user{
                    sender.isEnabled = false
                    spinner.removeFromSuperview()
                    UserDefaults.standard.set(user.uid, forKey: "UID")
                    self.performSegue(withIdentifier: "toAccountSetup", sender: nil)
                }
                else{
                    spinner.removeFromSuperview()
                    sender.isEnabled = true
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setKeyBoardNotifs()
        passwordField.becomeFirstResponder()
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
        bar.backgroundColor = UIColor(named: "LoadingColor")
        let stackView = UIStackView(frame: bar.frame)
        bar.addSubview(stackView)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        button.setTitle("NEXT", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont(name: "NexaW01-Heavy", size: button.titleLabel?.font.pointSize ?? 16)
        button.addTarget(self, action: #selector(doneEditing(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        
        return bar
    }()
    
    @objc func doneEditing(_ sender: UIButton){
        checkIfNext(sender: sender)
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

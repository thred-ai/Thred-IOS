//
//  PasswordResetVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-14.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import ColorCompatibility

class PasswordResetVC: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.inputAccessoryView = toolBar
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        emailField.layer.cornerRadius = emailField.frame.height / 2
        emailField.clipsToBounds = true
    }
    
    @IBAction func sendPasswordResetEmail(_ sender: UIButton) {
        sender.isEnabled = false
        guard let email = emailField.text, !email.isEmpty else{
            sender.isEnabled = true
            return}
        guard email.contains("@") else{
            updateErrorView(text: "Not a valid email")
            sender.isEnabled = true
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email, completion: { error in
            if let err = error{
                print(err.localizedDescription)
                self.updateErrorView(text: "Error sending email")
                sender.isEnabled = true
            }
            else{
                sender.isEnabled = true
                if let vc = self.navigationController?.viewControllers.first(where: {$0.isKind(of: SignInVC.self)}) as? SignInVC{
                    vc.errorView.text = "Check your email for the password reset link"
                    vc.errorView.textColor = UIColor(named: "LoadingColor")
                }
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    func updateErrorView(text: String){
        errorView.textColor = .systemRed
        errorView.text = text
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
        emailField.resignFirstResponder()
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

//
//  SignUpVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import Firebase

class SignUpVC: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var errorView: UITextView!
    var emailToUse: String!
    @IBOutlet weak var termsOfServiceView: UITextView!
    @IBOutlet weak var toSignInBtn: UIButton!
    
    @IBAction func toPassword(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        guard let text = emailField.text, !text.isEmpty, text.filter({$0 == "@"}).count == 1 else{
            updateErrorView(text: "Not a valid email")
            sender.isEnabled = true
            return}
        errorView.text = nil
        print(text)
        emailToUse = text
        self.performSegue(withIdentifier: "toPassword", sender: nil)
    }
    
    
    @IBAction func toSignIn(_ sender: UIButton) {
        
        if navigationController?.viewControllers.contains(where: {$0.isKind(of: SignInVC.self)}) ?? false{
            navigationController?.popViewController(animated: true)
        }
        else{
            performSegue(withIdentifier: "toSignIn", sender: nil)
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        emailField.layer.cornerRadius = emailField.frame.height / 2
        emailField.clipsToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        emailField.inputAccessoryView = toolBar
        addGuidelinesLink()

        if Auth.auth().currentUser != nil{
            toSignInBtn.isHidden = true
        }
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
    
    func addGuidelinesLink(){
        let linkWords = "Community Guidelines"
        let privWords = "Privacy Policy"

        let guideLineText = "By signing up for Thred, you agree to our \(linkWords) and \(privWords)"
        
        termsOfServiceView.text = guideLineText
        let attrString = NSMutableAttributedString()
        attrString.setAttributedString(termsOfServiceView.attributedText)
        let nsText = NSString(string: guideLineText)
        let matchRange:NSRange = nsText.range(of: linkWords)
        let matchRange2:NSRange = nsText.range(of: privWords)
        
        guard let font = UIFont(name: "NexaW01-Heavy", size: termsOfServiceView.font?.pointSize ?? 16) else{return}
        
        let attributes = [
            NSAttributedString.Key.link : "https://thredapps.com/community-guidelines",
            NSAttributedString.Key.font : font
        ] as [NSAttributedString.Key : Any]
        let attributes2 = [
            NSAttributedString.Key.link :
            "https://thredapps.com/privacy-policy",
            NSAttributedString.Key.font : font
        ] as [NSAttributedString.Key : Any]
        
        attrString.addAttributes(attributes, range: matchRange)
        attrString.addAttributes(attributes2, range: matchRange2)

        
        termsOfServiceView.attributedText = attrString
        termsOfServiceView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor(named: "LoadingColor")!
        ]
    }
    
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
    
    func updateErrorView(text: String){
        errorView.textColor = .systemRed
        errorView.text = text
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let passVC = segue.destination as? PasswordVC{
            passVC.emailToUse = emailToUse
        }
    }

}

var actionCodeSettings: ActionCodeSettings = {
    
    let link = URL(string: "https://thred.page.link/eNh4")
    let actionCodeSettings = ActionCodeSettings()
    actionCodeSettings.url = link
    // The sign-in operation has to always be completed in the app.
    actionCodeSettings.handleCodeInApp = true
    actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
    actionCodeSettings.setAndroidPackageName("com.example.android",
                                             installIfNotAvailable: false, minimumVersion: "12")
    return actionCodeSettings
}()

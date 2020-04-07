//
//  CodeViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-05-21.
//  Copyright © 2018 ARTACORP. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftKeychainWrapper
import FirebaseMessaging
import ColorCompatibility
import Firebase
import SDWebImage

class CodeViewController: UIViewController {
    
    var phoneNumber = String()
    
    @IBOutlet weak var verification: UITextField!
    @IBOutlet weak var termsOfServiceView: UITextView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var enter: UIBarButtonItem!
    @IBOutlet weak var errorView: UITextView!
    
    @IBOutlet weak var infoLbl: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        verification.inputAccessoryView = toolBar
        addGuidelinesLink()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setKeyBoardNotifs()
    }
    
    @IBAction func sendCodeAgain(_ sender: UIButton){
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            if let err = error {
                print(err.localizedDescription)
                self.errorView.text = "Incorrect Code"
                self.errorView.textColor = .systemRed
                sender.isEnabled = true
                return
            }
            else{
                self.errorView.text = "Code sent!"
                self.errorView.textColor = UIColor(named: "LoadingColor")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.errorView.text = nil
                    sender.isEnabled = true
                }
                UserDefaults.standard.set(verificationID, forKey: "VerificationID")
                print("SMS Sent")
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        verification.layer.cornerRadius = verification.frame.height / 2
        verification.clipsToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        verification.becomeFirstResponder()
        
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
        verification.resignFirstResponder()
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
    
    @IBAction func enter(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        let verificationID = UserDefaults.standard.string(forKey: "VerificationID")
        let verificationField = verification.text
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID!,
            verificationCode: verificationField!)
        
        if Auth.auth().currentUser == nil{
            Auth.auth().signIn(with: credential, completion: { (authResult, error) in
                if let err = error {
                    print(err.localizedDescription)
                    
                    self.errorView.text = error?.localizedDescription
                    self.errorView.textColor = .systemRed
                    sender.isEnabled = true
                    return
                }
                else{
                    print("Saved UID")
                    guard let userUID = Auth.auth().currentUser?.uid else{
                        
                        return}
                    UserDefaults.standard.set(userUID, forKey: "UID")
                    self.errorView.text = nil
                    let spinner = MapSpinnerView.init(frame: CGRect(x: 5, y: 5, width: self.errorView.frame.height, height: self.errorView.frame.height))
                    spinner.center = self.errorView.center
                    self.errorView.addSubview(spinner)
                    spinner.animate()
                    userInfo.uid = userUID
                    UserDefaults.standard.set(self.phoneNumber, forKey: "PHONE_NUM")
                    self.loadUser(userUID: userUID){ success in
                        if success{
                            self.performSegue(withIdentifier: "toProfile", sender: nil)
                        }
                        else{
                            self.performSegue(withIdentifier: "toSetup", sender: nil)
                        }
                    }
                }
            })
        }
        else{
            guard let uid = Auth.auth().currentUser?.uid else{return}
            Auth.auth().currentUser?.updatePhoneNumber(credential, completion: {(error) in
                if error != nil{
                    sender.isEnabled = true
                    self.errorView.text = error?.localizedDescription
                    self.errorView.textColor = .systemRed
                    print(error?.localizedDescription ?? "")
                    return
                }
                else{
                    Firestore.firestore().collection("Users").document(uid).updateData(["Phone" : self.phoneNumber], completion: { error in
                        
                        if let err = error{
                            print(err.localizedDescription)
                            self.errorView.text = err.localizedDescription
                            self.errorView.textColor = .systemRed
                        }
                        else{
                            self.errorView.text = nil
                            UserDefaults.standard.set(self.phoneNumber, forKey: "PHONE_NUM")
                            self.performSegue(withIdentifier: "UpdatedPhone", sender: nil)
                        }
                    })
                }
            })
        }
    }
    
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}


extension UIViewController{
    func loadUser(userUID: String, completed: @escaping (Bool) -> ()){
        self.downloadUserInfo(uid: userUID, userVC: nil, feedVC: nil, downloadingPersonalDP: true, doNotDownloadDP: false, downloader: SDWebImageDownloader.shared, userInfoToUse: nil, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postCount, followersCount, followingCount in
            
            if username == nil{
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5){
                    completed(false)
                }
            }
            else{
                if let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate{
                    appdelegate.registerNotifs(application: UIApplication.shared)
                }
                self.setUserInfo(username: username, fullname: fullName, image: imgData, bio: bio, notifID: notifID, dpUID: dpUID, userFollowing: userFollowing, followerCount: followersCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking)
                completed(true)
            }
        })
    }
}

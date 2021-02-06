//
//  UsernameSetupVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-01.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import ColorCompatibility
import FirebaseStorage
import FirebaseFirestore

class UsernameSetupVC: UIViewController {

    @IBOutlet weak var usernameView: UITextField!
    
    @IBOutlet weak var fullNameView: UITextField!
    
    @IBOutlet weak var errorView: UITextView!
    
    @IBOutlet weak var scrollView: UIScrollView!
        
    // add button global ref
    var nextBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameView.inputAccessoryView = toolBar
        fullNameView.inputAccessoryView = toolBar
        usernameView.addTarget(self, action: #selector(textFieldDidChange(_:)),
        for: .editingChanged)
        self.navigationItem.setHidesBackButton(true, animated: true)

        if let name = Auth.auth().currentUser?.displayName{
            fullNameView.text = name
        }
    }
    
    func checkIfNext(sender: UIButton){
        
        if usernameView.text?.isEmpty ?? false{
            fullNameView.resignFirstResponder()
            usernameView.becomeFirstResponder()
        }
        else if fullNameView.text?.isEmpty ?? false{
            usernameView.resignFirstResponder()
            fullNameView.becomeFirstResponder()
        }
        else{
            if canProceed(textField: usernameView){
                usernameView.resignFirstResponder()
                fullNameView.resignFirstResponder()
                done(sender)
            }
        }
    }
    
    var oldText: String!
    
    @objc func textFieldDidChange(_ textField: UITextField){
        
        guard var text = textField.text else {return}
        text = text.replacingOccurrences(of: " ", with: "_").lowercased()
        textField.text = text
        
        if text.hasSpecialCharacters(){
            textField.text = oldText
        }
        else{
            oldText = text
        }
        
    }
    
    func canProceed(textField: UITextField) -> Bool{
        if !(textField.text?.first == "." || textField.text?.last == ".") || textField.text?.count ?? 0 < 2{
            return true
        }
        else{
            return false
        }
    }

    
    func done(_ sender: UIButton) {
        sender.isEnabled = false
        guard let fieldText = usernameView.text else{
            sender.isEnabled = true
            return}
        let fullname = fullNameView.text ?? fieldText
        guard let user = Auth.auth().currentUser else{
            sender.isEnabled = true
            return}
        let uid = user.uid
        self.errorView.text = nil
        
        let spinner = MapSpinnerView.init(frame: CGRect(x: 5, y: 0, width: 20, height: 20))
        spinner.center.x = errorView.center.x
        errorView.addSubview(spinner)
        spinner.animate()
        
        Firestore.firestore().collection("Users").whereField("Username", isEqualTo: fieldText).getDocuments(completion: { snaps, error in
            
            if let err = error{
                print(err.localizedDescription)
                spinner.removeFromSuperview()
                self.updateErrorView(text: err.localizedDescription)
                sender.isEnabled = true
            }
            else{
                let doc = snaps?.documents.first
                if (snaps?.isEmpty ?? false) || doc?.documentID == uid{
                    guard let fieldText = self.usernameView.text else{
                        sender.isEnabled = true
                        spinner.removeFromSuperview()
                        return}

                        self.checkAuthStatus {
                            let data = [
                                "Full_Name" : fullname,
                                "Username" : fieldText,
                                "Bio" : "",
                                "ProfilePicID" : "",
                                "notification_tokens" : [],
                                "Following_List" : [],
                                "Following_Count" : 0,
                                "Followers_Count" : 0,
                                "Posts_Count" : 0,
                                ] as [String : Any]
                            Firestore.firestore().collection("Users").document(uid).setData(data, merge: true, completion: { error in
                                if let err = error{
                                    spinner.removeFromSuperview()
                                    self.updateErrorView(text: err.localizedDescription)
                                }
                                else{
                                    UserDefaults.standard.set(fieldText, forKey: "USERNAME")
                                    UserDefaults.standard.set(fullname, forKey: "FULLNAME")
                                    UserDefaults.standard.set(user.email ?? user.providerData.first?.email, forKey: "EMAIL")
                                    if user.email != nil{
                                        user.sendEmailVerification(with: actionCodeSettings, completion: { error in
                                            if let err = error{
                                                sender.isEnabled = true
                                                print(err.localizedDescription)
                                            }
                                        })
                                    }
                                    
                                    self.setDefaultDP(uid: uid){ success, dp, picID in
                                        sender.isEnabled = true
                                        if success{
                                            guard let defaultDP = dp else{return}
                                            self.setUserInfo(username: fieldText, fullname: fullname, image: defaultDP, bio: "", notifID: nil, dpUID: picID, userFollowing: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], verified: false)
                                            self.loadUserInfo()
                                            if let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate{
                                                appdelegate.registerNotifs(application: UIApplication.shared)
                                            }
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5){
                                                spinner.removeFromSuperview()
                                                self.performSegue(withIdentifier: "toProfile", sender: nil)
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    
                }
                else{
                    spinner.removeFromSuperview()
                    sender.isEnabled = true
                    self.updateErrorView(text: "This username is not available")
                }
            }
        })
    }
    
    func setDefaultDP(uid: String, completed: @escaping (Bool, Data?, String?) -> ()){
        
        var data = defaultDP
        if let imageURL = Auth.auth().currentUser?.providerData.first?.photoURL?.absoluteString, let url = URL(string: imageURL){
            
            do {
                data = try Data(contentsOf: url)
            } catch { print(error.localizedDescription) }
            
        }
        guard let defaultDP = data else{completed(true, nil, nil); return}
        guard let imageData = UIImage(data: defaultDP)?.sd_resizedImage(with: CGSize(width: 200, height: 200), scaleMode: .aspectFit)?.jpegData(compressionQuality: 0.6) else {return}
        let picID = NSUUID().uuidString.replacingOccurrences(of: "-", with: "")
        let ref = Storage.storage().reference().child("Users/" + uid + "/" + "profile_pic-" + picID + ".jpeg")
        ref.putData(imageData, metadata: nil, completion: { metaData, error in
            if let err = error{
                completed(true, nil, nil)
                print(err.localizedDescription)
            }
            else{
                self.errorView.text = nil
                UserDefaults.standard.set(picID, forKey: "DP_ID")
                pUserInfo.dp = defaultDP
                cache.storeImageData(toDisk: imageData, forKey: picID)
                DispatchQueue.main.async {
                    completed(true, imageData, picID)
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setKeyBoardNotifs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fullNameView.becomeFirstResponder()

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

    override func viewDidLayoutSubviews() {
        usernameView.layer.cornerRadius = usernameView.frame.height  / 2
        usernameView.clipsToBounds = true
        fullNameView.layer.cornerRadius = fullNameView.frame.height  / 2
        fullNameView.clipsToBounds = true
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

extension UIViewController{
    func loadUserInfo(){
        
        let uid = UserDefaults.standard.string(forKey: "UID")!
        pUserInfo.uid = uid

        let username = UserDefaults.standard.string(forKey: "USERNAME") ?? "null"
        pUserInfo.username = username
        let fullname = UserDefaults.standard.string(forKey: "FULLNAME") ?? "null"
        pUserInfo.fullName = fullname

        if let bio = UserDefaults.standard.string(forKey: "BIO"){
            pUserInfo.bio = bio
        }
        if let dpID = UserDefaults.standard.string(forKey: "DP_ID"){
            print(dpID)
            pUserInfo.dpID = dpID
            if let profilePic = cache.diskImageData(forKey: dpID){
                pUserInfo.dp = profilePic
            }
        }

        if let notifID = UserDefaults.standard.string(forKey: "NOTIF_ID"){
            pUserInfo.notifID = notifID
        }
        if let userLiked = UserDefaults.standard.stringArray(forKey: "LikedPosts"){
            pUserInfo.userLiked = userLiked
        }
        
        if let userFollowing = UserDefaults.standard.stringArray(forKey: "FOLLOWING"){
            pUserInfo.userFollowing = userFollowing
        }
        
        if let followerCount = UserDefaults.standard.object(forKey: "FOLLOWER_COUNT") as? Int{
            pUserInfo.followerCount = followerCount
        }
        
        if let postCount = UserDefaults.standard.object(forKey: "POST_COUNT") as? Int{
            pUserInfo.postCount = postCount
        }
        
        if let followingCount = UserDefaults.standard.object(forKey: "FOLLOWING_COUNT") as? Int{
            pUserInfo.followingCount = followingCount
        }
        if let verified = UserDefaults.standard.object(forKey: "VERIFIED") as? Bool{
            pUserInfo.verified = verified
        }
        if let blocking = UserDefaults.standard.stringArray(forKey: "BLOCKING"){
            pUserInfo.usersBlocking = blocking
        }
        if let likesToUpdate = UserDefaults.standard.object(forKey: "likeQueue") as? [String : Bool]{
            likeQueue = likesToUpdate
        }
        uploadingPosts.checkAndLoadProducts(type: "UploadProducts")
    }
}


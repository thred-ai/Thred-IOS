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
    
    @IBOutlet weak var nextBtn: UIBarButtonItem!
    
    var doneBtnPressed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameView.inputAccessoryView = toolBar
        fullNameView.inputAccessoryView = toolBar
        usernameView.addTarget(self, action: #selector(textFieldDidChange(_:)),
        for: .editingChanged)
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    var oldText: String!
    
    @objc func textFieldDidChange(_ textField: UITextField){
        
        guard var text = textField.text else {return}
        
        text = text.replacingOccurrences(of: " ", with: "_").lowercased()
        textField.text = text
        
        if text.count < 2{
            nextBtn.isEnabled = false
        }
        else{
            if text.hasSpecialCharacters(){
                textField.text = oldText
            }
            else{
                oldText = text
            }
            if !(textField.text?.first == "." || textField.text?.last == "."){
                nextBtn.isEnabled = true
            }
            else{
                nextBtn.isEnabled = false
            }
        }
    }
    

    
    @IBAction func done(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        guard let fieldText = usernameView.text else{return}
        let fullname = fullNameView.text ?? fieldText
        guard let uid = Auth.auth().currentUser?.uid else{return}
        self.errorView.text = nil
        Firestore.firestore().collection("Users").whereField("Username", isEqualTo: fieldText).getDocuments(completion: { snaps, error in
            
            if let err = error{
                print(err.localizedDescription)
                self.updateErrorView(text: err.localizedDescription)
                sender.isEnabled = true
            }
            else{
                let doc = snaps?.documents.first
                if (snaps?.isEmpty ?? false) || doc?.documentID == uid{
                    guard let fieldText = self.usernameView.text else{
                        sender.isEnabled = true
                        return}

                    DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                        let data = [
                            "Username": fieldText,
                            "Full_Name" : fullname
                        ]
                        self.checkAuthStatus {
                            Firestore.firestore().collection("Users").document(uid).updateData(data, completion: { error in
                                if let err = error{
                                    sender.isEnabled = true
                                    self.updateErrorView(text: err.localizedDescription)
                                }
                                else{
                                    UserDefaults.standard.set(fieldText, forKey: "USERNAME")
                                    UserDefaults.standard.set(fullname, forKey: "FULLNAME")
                                    self.setDefaultDP(uid: uid){ success in
                                        self.setProfileLink {
                                            sender.isEnabled = true
                                            if success{
                                                self.loadUserInfo()
                                                if let appdelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate{
                                                    appdelegate.registerNotifs(application: UIApplication.shared)
                                                }
                                                self.performSegue(withIdentifier: "toProfile", sender: nil)
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
                else{
                    sender.isEnabled = true
                    self.updateErrorView(text: "This username is not available")
                }
            }
        })
    }
    
    func setDefaultDP(uid: String, completed: @escaping (Bool) -> ()){
        guard let defaultDP = defaultDP else{completed(true); return}
        guard let imageData = UIImage(data: defaultDP)?.sd_resizedImage(with: CGSize(width: 200, height: 200), scaleMode: .aspectFit)?.jpegData(compressionQuality: 0.6) else {return}
        let picID = NSUUID().uuidString.replacingOccurrences(of: "-", with: "")
        let ref = Storage.storage().reference().child("Users/" + uid + "/" + "profile_pic-" + picID + ".jpeg")
        ref.putData(imageData, metadata: nil, completion: { metaData, error in
            if let err = error{
                completed(true)
                print(err.localizedDescription)
            }
            else{
                self.errorView.text = nil
                UserDefaults.standard.set(picID, forKey: "DP_ID")
                userInfo.dp = defaultDP
                cache.storeImageData(toDisk: imageData, forKey: picID)
                DispatchQueue.main.async {
                    completed(true)
                }
            }
        })
    }
    
    func setProfileLink(completed: @escaping () -> ()){
        
        getLink(completed: { url in
            UserDefaults.standard.set(url, forKey: "PROFILE_LINK")
            completed()
        })
    }

    func getLink(completed: @escaping (URL?) -> ()){
        let info = userInfo
        if info.profileLink == nil{
            generateLink(userInfo: info, completed: { link in
                info.profileLink = link
                completed(link)
            })
        }
        else{
            completed(info.profileLink)
        }
    }
        
    func getThumbnailURL(uid: String, dpID: String?, completed: @escaping (URL?) -> ()){
        guard let dpID = dpID else {
            completed(nil)
            return
        }

        let ref = Storage.storage().reference().child("Users/" + uid + "/" + "profile_pic-" + dpID + ".jpeg")
        ref.downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
                completed(nil)
            }
            else{
                completed(url)
            }
        })
        
    }
        
    func generateLink(userInfo: UserInfo, completed: @escaping (URL?) -> ()){
        guard let username = userInfo.username, let fullname = userInfo.fullName, let uid = userInfo.uid else{
            completed(nil)
            return}
        guard let link = URL(string: "https://thredapps.com/users/\(uid)") else {
            return }
        let dynamicLinksDomainURIPrefix = "https://thred.thredapps.com"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "thred.Thred")
        linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "com.example.android")
        linkBuilder?.iOSParameters?.appStoreID = "1506286170"
        let shareMessage = "\(fullname) (\(username)) • Thred design and sell"
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = shareMessage
        linkBuilder?.options = DynamicLinkComponentsOptions()
        linkBuilder?.options?.pathLength = .short
        getThumbnailURL(uid: uid, dpID: userInfo.dpID, completed: { url in
            linkBuilder?.socialMetaTagParameters?.imageURL = url
            guard let longDynamicLink = linkBuilder?.url else {
                completed(nil)
                return }
            print("The long URL is: \(longDynamicLink)")
            linkBuilder?.shorten() { url, warnings, error in
                if let err = error{
                    print(err.localizedDescription)
                    completed(nil)
                }
                else{
                    completed(url)
                    guard let url = url else { return }
                    print("The short URL is: \(url)")
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
        usernameView.resignFirstResponder()
        fullNameView.resignFirstResponder()
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
        userInfo.uid = uid

        let username = UserDefaults.standard.string(forKey: "USERNAME") ?? "null"
        userInfo.username = username
        let fullname = UserDefaults.standard.string(forKey: "FULLNAME") ?? "null"
        userInfo.fullName = fullname

        if let bio = UserDefaults.standard.string(forKey: "BIO"){
            userInfo.bio = bio
        }
        if let dpID = UserDefaults.standard.string(forKey: "DP_ID"){
            print(dpID)
            userInfo.dpID = dpID
            if let profilePic = cache.diskImageData(forKey: dpID){
                userInfo.dp = profilePic
            }
        }

        if let notifID = UserDefaults.standard.string(forKey: "NOTIF_ID"){
            userInfo.notifID = notifID
        }
        if let userLiked = UserDefaults.standard.stringArray(forKey: "LikedPosts"){
            userInfo.userLiked = userLiked
        }
        
        if let userFollowing = UserDefaults.standard.stringArray(forKey: "FOLLOWING"){
            userInfo.userFollowing = userFollowing
        }
        
        if let followerCount = UserDefaults.standard.object(forKey: "FOLLOWER_COUNT") as? Int{
            userInfo.followerCount = followerCount
        }
        
        if let postCount = UserDefaults.standard.object(forKey: "POST_COUNT") as? Int{
            userInfo.postCount = postCount
        }
        
        if let followingCount = UserDefaults.standard.object(forKey: "FOLLOWING_COUNT") as? Int{
            userInfo.followingCount = followingCount
        }
        if let verified = UserDefaults.standard.object(forKey: "VERIFIED") as? Bool{
            userInfo.verified = verified
        }
        if let blocking = UserDefaults.standard.stringArray(forKey: "BLOCKING"){
            userInfo.usersBlocking = blocking
        }
        if let likesToUpdate = UserDefaults.standard.object(forKey: "likeQueue") as? [String : Bool]{
            likeQueue = likesToUpdate
        }
        if let uploadPosts = UserDefaults.standard.stringArray(forKey: "UploadingPosts"){
            uploadingPosts = uploadPosts
        }
    }
}

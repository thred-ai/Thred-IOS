//
//  ProfileHeaderView.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-02.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import ColorCompatibility
import FirebaseStorage
import FirebaseDynamicLinks
import FirebaseFirestore

class ProfileHeaderView: UIView, UITextViewDelegate{

    var selectedList: UserListType!
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    @IBAction func showMessage(_ sender: UIButton) {
        getViewController()?.showAuthMessage {
            
        }
    }
    
    @IBAction func toFollowingList(_ sender: UITapGestureRecognizer) {
        selectedList = .following
        getViewController()?.performSegue(withIdentifier: "toUserList", sender: nil)
    }
    
    @IBAction func toFollowerList(_ sender: UITapGestureRecognizer) {
        selectedList = .followers
        getViewController()?.performSegue(withIdentifier: "toUserList", sender: nil)
    }
    
    @IBAction func showPosts(_ sender: UITapGestureRecognizer) {
        
    }
    
    
    
    
    
    override func draw(_ rect: CGRect) {
    }
    @IBOutlet weak var optionBtn: UIButton!
    
    
    @IBOutlet weak var followingNum: UILabel!
    @IBOutlet weak var followerNum: UILabel!
    @IBOutlet weak var postNum: UILabel!
    
    @IBOutlet weak var emailNotSetView: UIButton!
    
    @IBOutlet weak var shareProfileBtn: UIButton!
    @IBOutlet weak var userContentView: UIView!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var bioView: UITextView!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var profileImgView: UIImageView!
    var headerActionBtnTitle: String = "Loading"
    var vc: UIViewController!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
        bioView.delegate = self
        shareProfileBtn.setImage(UIImage(nameOrSystemName: "arrowshape.turn.up.right", systemPointSize: 17, iconSize: 7), for: .normal)
    }
    @IBOutlet weak var progressView: UIProgressView!
    
    func animateProgressBar(value: CGFloat){
        self.progressView.setProgress(Float(value), animated: true)
    }
    
    @IBAction func shareAccount(_ sender: UIButton) {
      
        guard fullnameLbl.text != nil, !(fullnameLbl.text?.isEmpty ?? false) else{return}
        guard usernameLbl.text != nil, !(usernameLbl.text?.isEmpty ?? false) else{return}
        animateProgressBar(value: 0.2)
        
        
        getLink(completed: { url in
            guard let url = url else{return}
            self.animateProgressBar(value: 1.0)
            let activity = UIActivityViewController(
                  activityItems: [url],
                  applicationActivities: nil
            )
            //activity.popoverPresentationController?.bu
                // 3
            self.getViewController()?.present(activity, animated: true, completion: nil)
            DispatchQueue.main.async {
                self.progressView.setProgress(0.0, animated: false)
            }
        })
    }
    
    func getLink(completed: @escaping (URL?) -> ()){
        self.animateProgressBar(value: 0.4)
        let info = (vc as? FriendVC)?.friendInfo ?? userInfo
        if info.profileLink == nil{
            generateLink(userInfo: info, completed: { link in
                info.profileLink = link
                self.animateProgressBar(value: 0.8)
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
        guard let link = URL(string: "https://thredapps.com/users/\(username)/\(uid)") else {
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
            self.animateProgressBar(value: 0.6)
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
    
    
    func clearAll(actionBtnTitle: String){
        usernameLbl.text = nil
        fullnameLbl.text = nil
        bioView.text = nil
        actionBtn.setTitle(actionBtnTitle, for: .normal)
        profileImgView.image = nil
        setNeedsLayout()
        layoutIfNeeded()
    }

    func adjustBioHeight(){
        let width = self.bioView.frame.width
        let newBioHeight = self.bioView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
        if newBioHeight < self.bioView.frame.height{
             let difference = self.bioView.frame.height - newBioHeight
             self.frame.size.height -= difference
        }
        else if newBioHeight > self.bioView.frame.height{
            let difference = newBioHeight - self.bioView.frame.height
            print(self.bioView.frame.height)
            print(newBioHeight)
            print(difference)
            
            self.frame.size.height += difference
        }
    }
    

    func updateFollowBtn(didFollow: Bool, animated: Bool){
        var animationDuration = 0.0
        
        if animated{
            animationDuration = 0.2
        }
        if didFollow{
            headerActionBtnTitle = "Following"
            actionBtn.setTitleColor(.white, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn .backgroundColor = UIColor(named: "LoadingColor")
            })
        }
        else{
            headerActionBtnTitle = "Follow"
            actionBtn.setTitleColor(.label, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn.backgroundColor = .quaternarySystemFill
            })
        }
        actionBtn.titleLabel?.text = headerActionBtnTitle
        actionBtn.setTitle(headerActionBtnTitle, for: .normal)
    }
    
    func setUpInfo(username: String?, fullname: String?, bio: String?, notifID: String?, dpUID: String?, image: Data?, actionBtnTitle: String, followerCount: Int, followingCount : Int, postCount: Int){
        
        if let attr = bioView.attributedText.mutableCopy() as? NSMutableAttributedString{
            attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
            attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: bioView.font?.pointSize ?? 16)!], range: NSMakeRange(0, attr.length))
            bioView.attributedText = attr
        }
        
        bioView?.text = nil
        usernameLbl.text = "@" + (username ?? "null")
        fullnameLbl.text = fullname ?? "null"
        bioView.text = bio
        bioView.addLinks(isNotification: false)
        bioView.textAlignment = .center
        followerNum.text = "\(followerCount)"
        followingNum.text = "\(followingCount)"
        postNum.text = "\(postCount)"
        actionBtn.titleLabel?.text = actionBtnTitle
        actionBtn.setTitle(actionBtnTitle, for: .normal)
        setNeedsLayout()
        layoutIfNeeded()
        guard let img = image else{
            return}
        profileImgView.image = UIImage(data: img)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if let scheme = URL.scheme{
            if interaction == .preview{
                return false
            }
            if scheme.starts(with: "mention"){
                let username = URL.absoluteString.replacingOccurrences(of: "mention:", with: "")
                if username != userInfo.username, username != (vc as? FriendVC)?.friendInfo.username{
                    let user = UserInfo(uid: nil, dp: nil, dpID: nil, username: username, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil)
                    (vc as? FriendVC)?.selectedUser = user
                    (vc as? UserVC)?.selectedUser = user
                    vc?.performSegue(withIdentifier: "toFriend", sender: nil)
                }
            }
            else{
                return true
            }
        }
        return false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        profileImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        adjustBioHeight()
        userContentView.layer.cornerRadius =  userContentView.frame.width / 25
        userContentView.clipsToBounds = true
        userContentView.backgroundColor = UIColor(named: "ProfileMask")?.withAlphaComponent(0.25)
        profileImgView.layer.cornerRadius =  profileImgView.frame.height / 2
        profileImgView.clipsToBounds = true
        profileImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        profileImgView.layer.borderWidth = profileImgView.frame.width / 17.75
        actionBtn.layer.cornerRadius = actionBtn.frame.height / 4
        actionBtn.clipsToBounds = true
        shareProfileBtn.layer.cornerRadius = shareProfileBtn.frame.height / 4
        shareProfileBtn.clipsToBounds = true
        if vc == nil{
            vc = getViewController()
        }
    }
}

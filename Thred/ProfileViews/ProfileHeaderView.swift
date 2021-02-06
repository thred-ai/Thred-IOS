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
import PopupDialog
import FirebaseAnalytics
import SDWebImage

class StoryPost{
    
    var timestamp: Date!
    var storyID: String!
    var posts: [String]!
    
    init(timestamp: Date!, storyID: String!, posts: [String]){
        self.timestamp = timestamp
        self.storyID = storyID
        self.posts = posts
    }
    
    convenience init() {
        self.init(timestamp: nil, storyID: nil, posts: [])
    }
}

class ProfileHeaderView: UICollectionReusableView, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource{

    var selectedList: UserListType!
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var loadedPosts = [StoryPost]()
    
    func getStories(completed: @escaping () -> ()){
        Firestore.firestore().collection("Users/\(uid ?? "")/Stories").getDocuments(completion: { snaps, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                guard let docs = snaps?.documents else{ completed(); return }
                for doc in docs{
                    let timestamp = doc["Timestamp"] as? Date
                    let storyID = doc.documentID
                    let posts = doc["Posts"] as? [String]

                    let story = StoryPost(timestamp: timestamp, storyID: storyID, posts: posts ?? [])
                    self.loadedPosts.append(story)
                }
                completed()
            }
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return loadedPosts.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "storiesCell", for: indexPath) as? StoriesCell
        cell?.imageView.image = nil
        if indexPath.row == 0{
            
            
            cell?.imageView.image = UIImage(systemName: "plus.circle.fill")
            cell?.imageView.tintColor = .systemFill
            return cell!
        }
        
        
        let post = loadedPosts[indexPath.item - 1]
        
        guard let picIDs = post.posts else{return cell!}
        
        for picID in picIDs{
            
            if let img = cache.imageFromCache(forKey: picID){
                cell?.imageView.image = img
                cache.removeImageFromDisk(forKey: picID)
            }
            else{
                getStoryImage(uid: pUserInfo.uid ?? "", picID: picID, completed: { image in
                    if let index = self.loadedPosts.firstIndex(where: {$0.storyID == post.storyID}){
                        collectionView.performBatchUpdates({
                            collectionView.reloadItems(at: [IndexPath(item: index + 1, section: 0)])
                        }, completion: nil)
                    }
                })
            }
        }
        
        return cell!
    }
    
    
    func getStoryImage(uid: String, picID: String, completed: @escaping (UIImage?) -> ()){
        let ref = Storage.storage().reference().child("Users/" + uid + "/" + "Stories/" + picID + "/" + picID + ".jpeg")
        ref.downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                var dub: CGFloat = 0
                let oldDub: CGFloat = 0
                downloader.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                    dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                    print("Progress \(dub)")
                    print("Old Progress \(oldDub)")
                    DispatchQueue.main.async {
                        
                        //cp?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                            //oldDub = dub
                        //}
                    }
                }, completed: {(image, data, error, finished) in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        //completed(nil, picID)
                    }
                    else{
                        if let imgData = data{
                            cache.storeImageData(toDisk: imgData, forKey: picID)
                        }
                        completed(image)
                    }
                })
                
            }
        })
                
    }
    
    
    @IBOutlet weak var dmBtn: UIButton!
    @IBAction func messageUser(_ sender: UIButton) {
        guard let friendVC = vc as? FriendVC, let uid = pUserInfo.uid, let friendUID = friendVC.friendInfo.uid else{return}
        
        
        breakLbl:
            if let viewControllers = friendVC.navigationController?.viewControllers, let index = viewControllers.firstIndex(of: friendVC), viewControllers.indices.contains(index - 1){
            guard let chatVC = viewControllers[index - 1] as? ChatVC, chatVC.chatInfo.displayUserInfo.uid == friendUID else{break breakLbl}
            
            friendVC.navigationController?.popViewController(animated: true)
            return
        }
    
        
        
        vc?.queryExistingChats(uid: uid, friendUID: friendUID, friendUserInfo: friendVC.friendInfo, completed: { chat in
            
            if let chat = chat{
                friendVC.selectedChat = chat
            }
            else{
                let docID = Firestore.firestore().collection("Chats").document().documentID
                let uids = [uid, friendUID]
                let chat = GroupChat(uids: uids, chatID: docID, userImageIDs: nil, timestamp: Date(), isActive: false, index: 0, activeTime: Date(), activeTimeDiff: nil, timestampDiff: nil, lastText: nil, chatName: friendVC.friendInfo.fullName, displayUserInfo: friendVC.friendInfo, didMute: false)
                friendVC.selectedChat = chat
            }
            
            self.vc?.performSegue(withIdentifier: "toChat", sender: nil)

        })
    }
    
    @IBAction func showMessage(_ sender: UIButton) {
        getViewController()?.showAuthMessage {
            
            
        }
    }
    @IBOutlet weak var followingStack: UIStackView!
    
    @IBOutlet weak var followerStack: UIStackView!
    
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
        shareProfileBtn?.setImage(UIImage(nameOrSystemName: "arrowshape.turn.up.right", systemPointSize: 17, iconSize: 7), for: .normal)
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        // Initialization code
        
        collectionView?.register(UINib(nibName: "StoriesCell", bundle: nil), forCellWithReuseIdentifier: "storiesCell")
        
        for (index, stack) in ([followingStack, followerStack]).enumerated(){
            var gesture: UITapGestureRecognizer!
            if index == 0{
                gesture = UITapGestureRecognizer(target: self, action: #selector(toFollowingList(_:)))
            }
            else{
                gesture = UITapGestureRecognizer(target: self, action: #selector(toFollowerList(_:)))
            }
            stack?.addGestureRecognizer(gesture)
        }
        
    }
    
    @objc func toSettings(_ sender: UIButton?){
        vc?.performSegue(withIdentifier: "toSettings", sender: nil)
    }
    
    
    @objc func editProfile(_ sender: UIButton){
        vc?.performSegue(withIdentifier: "editProfile", sender: nil)
    }
    
    @objc func openOptionMenu(_ sender: UIButton){

        
        
        let reportBtn = DefaultButton(title: "REPORT", dismissOnTap: true) {
            (self.vc as? FriendVC)?.reportType = .profile
            self.vc?.performSegue(withIdentifier: "toReport", sender: nil)
        }
        var blockTitle = "BLOCK"
        if (self.vc as? FriendVC)?.friendInfo.usersBlocking.contains(pUserInfo.uid ?? "") ?? false{
            blockTitle = "UNBLOCK"
        }
        let blockBtn = DefaultButton(title: blockTitle, dismissOnTap: true) {
            (self.vc as? FriendVC)?.blockUser(nil)
        }
        
        var notifTitle = "ON"
        
        if (self.vc as? FriendVC)?.friendInfo.postNotifsList.contains(pUserInfo.uid ?? "") ?? false{
            notifTitle = "OFF"
        }
        let postNotifsBtn = DefaultButton(title: "TURN \(notifTitle) POST NOTIFICATIONS", dismissOnTap: true) {
            (self.vc as? FriendVC)?.changePostNotifs(nil)
        }
        
        let shareBtn = DefaultButton(title: "SHARE PROFILE", dismissOnTap: true) {
            self.shareAccount(sender)
        }
        
        let cancelBtn = DefaultButton(title: "CANCEL", dismissOnTap: true) {
            
        }
        
        vc?.showPopUp(title: nil, message: nil, image: nil, buttons: [reportBtn, blockBtn, postNotifsBtn, shareBtn, cancelBtn], titleColor: .label, blurBack: false)
    }
    
    @objc func followBtnPressed(_ sender: UIButton){
        guard let friendVC = vc as? FriendVC else{return}
        let following = pUserInfo.userFollowing
        guard let uid = friendVC.friendInfo.uid else{
            return}
        let didFollow = !following.contains(uid)
        updateFollowBtn(didFollow: didFollow, animated: true)
        friendVC.updateFollowInDatabase(didFollow: didFollow)
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    
    func animateProgressBar(value: CGFloat){
        self.progressView.setProgress(Float(value), animated: true)
    }
    
    @IBAction func shareAccount(_ sender: UIButton) {
      
        guard fullnameLbl.text != nil, !(fullnameLbl.text?.isEmpty ?? false) else{return}
        guard usernameLbl.text != nil, !(usernameLbl.text?.isEmpty ?? false) else{return}
        animateProgressBar(value: 0.2)
        
        Analytics.logEvent("share_profile", parameters: [
        "name": "Profile Share",
        "full_text": "A profile was shared with a Dynamic Link"
        ])
        
        
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
        let info = (vc as? FriendVC)?.friendInfo ?? pUserInfo
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
        let shareMessage = "\(fullname) (\(username)) • Thred design, interact and sell"
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = shareMessage
        linkBuilder?.options = DynamicLinkComponentsOptions()
        linkBuilder?.options?.pathLength = .short
        getThumbnailURL(uid: uid, dpID: userInfo.dpID, completed: { url in
            self.animateProgressBar(value: 0.6)
            linkBuilder?.socialMetaTagParameters?.imageURL = url
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
        usernameLbl?.text = nil
        fullnameLbl?.text = nil
        bioView?.text = nil
        print(actionBtnTitle)
        actionBtn.setTitle(actionBtnTitle, for: .normal)
        profileImgView.image = nil
    }

    func adjustBioHeight(){
        guard let width = self.bioView?.frame.width else{return}
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
        let layout = (vc as? UserVC)?.collectionView.collectionViewLayout as? UICollectionViewFlowLayout ?? (vc as? FriendVC)?.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.headerReferenceSize = frame.size
    }
    

    func updateFollowBtn(didFollow: Bool, animated: Bool){
        var animationDuration = 0.0
        
        if animated{
            animationDuration = 0.2
        }
        if didFollow{
            headerActionBtnTitle = "Following"
            actionBtn?.setTitleColor(.white, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn?.backgroundColor = UIColor(named: "LoadingColor")
            })
        }
        else{
            headerActionBtnTitle = "Follow"
            actionBtn?.setTitleColor(.label, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn?.backgroundColor = .quaternarySystemFill
            })
        }
        actionBtn?.titleLabel?.text = headerActionBtnTitle
        actionBtn?.setTitle(headerActionBtnTitle, for: .normal)
    }
    
    func setUpInfo(username: String?, fullname: String?, bio: String?, notifID: String?, dpUID: String?, image: Data?, actionBtnTitle: String, followerCount: Int, followingCount : Int, postCount: Int, verified: Bool){
        
    
        if let attr = bioView?.attributedText.mutableCopy() as? NSMutableAttributedString{
            attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
            attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: bioView?.font?.pointSize ?? 16)!], range: NSMakeRange(0, attr.length))
            bioView.attributedText = attr
        }
        
        bioView?.text = nil
        if let name = username{
            usernameLbl?.text = "@" + name
        }
        fullnameLbl?.text = fullname ?? "null"
        if verified{
            fullnameLbl?.setVerified(name: fullname ?? "null")
        }
        bioView?.text = bio
        bioView?.addLinks(isNotification: false, prefix: "@")
        bioView?.addLinks(isNotification: false, prefix: "#")

        bioView?.textAlignment = .center
        followerNum?.text = "\(followerCount.kmFormatted)"
        followingNum?.text = "\(followingCount.kmFormatted)"
        postNum?.text = "\(postCount.kmFormatted)"
        actionBtn?.titleLabel?.text = actionBtnTitle
        actionBtn?.setTitle(actionBtnTitle, for: .normal)
        
        guard let img = image else{
            
            return}
        profileImgView?.image = UIImage(data: img)
        
        
    }
    
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if let scheme = URL.scheme{
            if interaction == .preview{
                return false
            }
            if scheme.starts(with: "mention"){
                let username = URL.absoluteString.replacingOccurrences(of: "mention:", with: "")
                if username != pUserInfo.username, username != (vc as? FriendVC)?.friendInfo.username{
                    let user = UserInfo(uid: nil, dp: nil, dpID: nil, username: username, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
                    (vc as? FriendVC)?.selectedUser = user
                    (vc as? UserVC)?.selectedUser = user
                    vc?.performSegue(withIdentifier: "toFriend", sender: nil)
                }
            }
            else if scheme.starts(with: "hashtag"){
                let tag = URL.absoluteString.replacingOccurrences(of: "hashtag:", with: "")
                let hashtag = Hashtag(postsCount: nil, array: nil, display: tag, offset: 0, downloading: [], tagDownloading: [], blurred: nil, topPost: nil)
                (vc as? FriendVC)?.hashtagToOpen = hashtag
                (vc as? UserVC)?.hashtagToOpen = hashtag
                
                vc?.performSegue(withIdentifier: "toHashtag", sender: nil)
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
        profileImgView.layer.cornerRadius =  profileImgView.frame.height / 2
        profileImgView.clipsToBounds = true
        profileImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        profileImgView.layer.borderWidth = profileImgView.frame.width / 17.75
        actionBtn.layer.cornerRadius = actionBtn.frame.height / 4
        actionBtn.clipsToBounds = true
        shareProfileBtn?.layer.cornerRadius = (shareProfileBtn?.frame.height ?? 0) / 4
        shareProfileBtn?.clipsToBounds = true
        
        
        dmBtn?.layer.cornerRadius = (dmBtn?.frame.height ?? 0) / 4
        dmBtn?.clipsToBounds = true
        
        if vc == nil{
            vc = getViewController()
            switch vc{
                
            case _ as UserVC:
                actionBtn.addTarget(self, action: #selector(editProfile(_:)), for: .touchUpInside)
                optionBtn.setImage(UIImage(named: "gear"), for: .normal)
                optionBtn.addTarget(self, action: #selector(toSettings(_:)), for: .touchUpInside)
            case _ as FriendVC:
                actionBtn.addTarget(self, action: #selector(followBtnPressed(_:)), for: .touchUpInside)
                actionBtn.isUserInteractionEnabled = true
                optionBtn.setImage(UIImage(nameOrSystemName: "ellipsis.circle", systemPointSize: 20, iconSize: 7), for: .normal)
                optionBtn.addTarget(self, action: #selector(openOptionMenu(_:)), for: .touchUpInside)
            default:
                return
            }
        }
    }
}

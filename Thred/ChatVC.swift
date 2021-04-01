//
//  ChatVC.swift
//  Artachat
//
//  Created by Arta Koroushnia on 2019-11-13.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import FirebaseFirestore
import Photos
import AVFoundation
import PopupDialog
import FirebaseAnalytics

class TextMessage: Equatable{
    
    static func == (lhs: TextMessage, rhs: TextMessage) -> Bool {
        return true
    }
    
    var uid = String()
    var message: String?
    var textID = String()
    var isPic: Bool
    var dp: UIImage?
    var fullname: String?
    var username: String?
    var timestamp = String()
    var dpID: String?
    var index: Int?
    var messageImg: UIImage?
    var aspectRatio: CGFloat?
    var estimatedHeight: CGFloat?
    var date: String?
    var rawDate: Date?
    var removed: Bool?
    var readBy: [String]!

    init(uid: String, message: String?, textID: String, isPic: Bool, dp: UIImage?, fullname: String?, username: String?, timestamp: String, dpID: String?, index: Int?, messageImg: UIImage?, aspectRatio: CGFloat?, estimatedHeight: CGFloat?, date: String?, rawDate: Date?) {
        
        self.uid = uid
        self.message = message
        self.textID = textID
        self.isPic = isPic
        self.dp = dp
        self.fullname = fullname
        self.username = username
        self.timestamp = timestamp
        self.dpID = dpID
        self.index = index
        self.messageImg = messageImg
        self.aspectRatio = aspectRatio
        self.estimatedHeight = estimatedHeight
        self.date = date
        self.rawDate = rawDate
    }
    
    convenience init(){
        self.init(uid: "", message: nil, textID: "", isPic: false, dp: nil, fullname: nil, username: nil, timestamp: "", dpID: nil, index: nil, messageImg: nil, aspectRatio: nil, estimatedHeight: nil, date: nil, rawDate: nil)
    }
}

class GroupChat: Codable, Equatable{
    
    static func == (lhs: GroupChat, rhs: GroupChat) -> Bool {
        return true
    }
    
    var uids = [String]()
    var chatID = String()
    var userImageIDs: [String]? = nil
    var timestamp: Date! = nil
    var isActive: Bool! = nil
    var index: Int! = nil
    var activeTime: Date! = nil
    var activeTimeDiff: String! = nil
    var timestampDiff: String! = nil
    var lastText: String!
    var chatName: String!
    var displayUserInfo: UserInfo!
    var didRead: Bool!
    var didMute: Bool!

    init(uids: [String]?, chatID: String, userImageIDs: [String]?, timestamp: Date!, isActive: Bool!, index: Int!, activeTime: Date!, activeTimeDiff: String!, timestampDiff: String!, lastText: String?, chatName: String?, displayUserInfo: UserInfo!, didMute: Bool!) {
        
        self.chatID = chatID
        self.timestamp = timestamp
        self.isActive = isActive
        self.index = index
        self.activeTime = activeTime
        self.activeTimeDiff = activeTimeDiff
        self.timestampDiff = timestampDiff
        self.lastText = lastText
        self.chatName = chatName
        self.displayUserInfo = displayUserInfo
        self.uids = uids ?? []
        self.didMute = didMute
    }
    
    convenience init() {
        self.init(uids: [], chatID: "", userImageIDs: [], timestamp: nil, isActive: nil, index: nil, activeTime: nil, activeTimeDiff: nil, timestampDiff: nil, lastText: nil, chatName: nil, displayUserInfo: nil, didMute: nil)
    }
    
}

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, AVCapturePhotoCaptureDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    var chatInfo = GroupChat()
    var downloadingProfiles = [String]()
    var tokens = [String]()
    var cellHeights: [IndexPath: CGFloat] = [:]
    var allMessages = [[TextMessage]]()
    var images = [PHAsset]()
    var selectedUser: UserInfo!

    @IBOutlet weak var bottomBarInnerView: UIView!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var bottomBar: UIView!
    
    @IBOutlet weak var bottomBarHeight: NSLayoutConstraint!
    @IBOutlet var tableView: UITableView!

    @IBOutlet weak var sendTextBtn: UIButton!
    //var loadingHeaderView: LoadingHeaderView?
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if let vc = viewController as? AllChatsVC, chatInfo.isActive{
            
            var lastText: String!
            
            guard allMessages.indices.contains(0), allMessages[0].indices.contains(0) else{return}
                
            let last = allMessages[0][0]
                
            var lastMsg = last.message
            
            if lastMsg == nil{
                lastMsg = "sent a photo"
                if last.uid == pUserInfo.uid{
                    lastMsg = "You \(lastMsg ?? "")"
                }
            }
            else{
                if last.uid == pUserInfo.uid{
                    lastMsg = "You: \(lastMsg ?? "")"
                }
            }
            
            if last.removed ?? false{
                lastMsg = "unsent a message"
                if last.uid == pUserInfo.uid{
                    lastMsg = "You \(lastMsg ?? "")"
                }
            }
            
            lastText = lastMsg
            
            chatInfo.lastText = lastText
            
            chatInfo.didRead = last.readBy.contains(pUserInfo.uid ?? "")
            
            if let chatIndex = vc.chats.firstIndex(where: {$0.chatID == chatInfo.chatID}){
                vc.chats[chatIndex].lastText = lastText
                vc.chats[chatIndex].timestamp = chatInfo.timestamp
                vc.chats[chatIndex].didRead = chatInfo.didRead
            }
            else{
                vc.chats.insert(chatInfo, at: 0)
            }
            vc.chats.sort(by: {$0.timestamp > $1.timestamp})
            
            DispatchQueue.main.async {
                vc.tableView.reloadData()
                vc.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        tableView.delegate = self
        tableView.dataSource = self
        textView.delegate = self
        navigationController?.delegate = self
        self.tableView.register(UINib(nibName: "TextMessageCell", bundle: nil), forCellReuseIdentifier: "textmsg")
        self.tableView.register(UINib(nibName: "PicMessageCell", bundle: nil), forCellReuseIdentifier: "picmsg")
        
        self.tableView.register(UINib(nibName: "UserPicMessageCell", bundle: nil), forCellReuseIdentifier: "userpicmsg")
        
        self.tableView.register(UINib(nibName: "UserTextMessageCell", bundle: nil), forCellReuseIdentifier: "usertextmsg")
        
        //self.loadingHeaderView = LoadingHeaderView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        self.tableView.alpha = 0.0
        
                
        tableView.allowsSelection = false
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)

        NotificationCenter.default.addObserver(self, selector: #selector(appAppeared(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDisappeared(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        

        initialWidth = textView.frame.width
        initialHeight = textView.frame.height
        previousHeight = textView.frame.height
        
        self.textViewDidChange(self.textView)
        
        bottomBarInnerView.layer.cornerRadius = bottomBarInnerView.frame.height / 2
        bottomBarInnerView.clipsToBounds = true
        self.setPlaceholder(textView: textView, textColor: .secondaryLabel)
       
        if !self.view.subviews.contains(self.zoomableView){
            self.view.addSubview(self.zoomableView)
            self.zoomableView.isHidden = true
        }
        
        //self.tableView.tableFooterView = self.loadingHeaderView
        //self.loadingHeaderView?.cp.isHidden = true

        self.navigationItem.title = chatInfo.chatName
        
        self.isLoadingTexts = true

        checkAndDownloadChatInfo {
            
            if let data = self.chatInfo.displayUserInfo?.dp, let image = UIImage(data: data){
                self.setTitle(self.chatInfo.chatName, andImage: image.sd_resizedImage(with: CGSize(width: 30, height: 30), scaleMode: .aspectFill))
            }
            
            self.load(fromInterval: ""){ query, isEmpty in
                if isEmpty{
                    self.isLoadingTexts = false
                    //self?.loadingHeaderView?.cp.isHidden = true
                }
                self.loadMessages(fromInterval: "", query: query){
                    self.isLoadingTexts = false
                    if (self.allMessages.joined().count) >= 15{
                        //self?.loadingHeaderView?.cp.isHidden = false
                    }
                    else{
                        //self?.loadingHeaderView?.cp.isHidden = true
                    }
                }
            }
        }
    }
    
    func setTitle(_ title: String, andImage image: UIImage?) {
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.textColor = UIColor.label
        titleLbl.font = UIFont(name: "NexaW01-Heavy", size: 16)
        let imageView = UIImageView(image: image)
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        imageView.layer.borderWidth = imageView.frame.width / 17.75
        let titleView = UIStackView(arrangedSubviews: [imageView, titleLbl])
        titleView.axis = .horizontal
        titleView.spacing = 7.5
        let tapper = UITapGestureRecognizer(target: self, action: #selector(toProfile(sender:)))
        tapper.numberOfTapsRequired = 1
        titleView.addGestureRecognizer(tapper)
        navigationItem.titleView = titleView
    }
    
    @objc func toProfile(sender: Any?){
        selectedUser = chatInfo.displayUserInfo
        self.performSegue(withIdentifier: "toFriend", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        hideCenterBtn()
        self.setKeyBoardNotifs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        (UIApplication.shared.delegate as? AppDelegate)?.checkNotifInfo(force: false)
    }
    
    var isLoadingTexts = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bottomBarInnerView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        bottomBarInnerView.layer.borderWidth = 1.5
        initialWidth = textView.frame.width
        initialHeight = textView.frame.height
        previousHeight = textView.frame.height
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        bottomBarInnerView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        
        if let titleview = self.navigationItem.titleView, let imageView = titleview.subviews.first as? UIImageView{
            imageView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {

        self.textView.becomeFirstResponder()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        
        self.scrollToBottom(animate: true)
        
        return false
    }
    
    func scrollToBottom(animate: Bool)  {
        DispatchQueue.main.async {
            let point = CGPoint(x: 0, y: self.tableView.contentSize.height + self.tableView.contentInset.bottom - self.tableView.frame.height)
            if point.y >= 0{
                self.tableView.setContentOffset(point, animated: animate)
            }
        }
    }
    
    func configurePhotos(_ sender: UIButton) {
        if self.cameraRollCollectionView.isHidden{
            sender.tintColor = .cyan
            //exitTapper.isEnabled = true
            textView.resignFirstResponder()
            showCamRoll(sender: sender)
        }
        else{
            sender.tintColor = UIColor(named: "LoadingColor")
            cameraRollCollectionView.animatehideCameraRoll(viewToCarry: bottomBar, backgroundView: view, tableView: nil){
            }
        }
    }
    
    func checkToCreateChat(completed: @escaping () -> ()){
        
        if !chatInfo.isActive{
            chatInfo.isActive = true
            let data = [
                "Timestamp" : chatInfo.timestamp ?? Date(),
                "Active" : chatInfo.activeTime ?? Date(),
                "Members" : chatInfo.uids.sortedAlphabet(),
                "Original_Members" : chatInfo.uids.sortedAlphabet()
            ] as [String : Any]
            
            Firestore.firestore().collection("Chats").document(chatInfo.chatID).setData(data, completion: { error in
                 completed()
            })
        }
        else{
            completed()
        }
    }
        
    @objc func appAppeared(_ notification: Notification){

        /*
        if let header = self.loadingHeaderView{
            if header.subviews.contains(header.cp){
                header.addViewSpinner(centerX: header.frame.width / 2, centerY: header.frame.height / 2, width: 40, height: 40)
            }
        }
 */
    }
    
    @objc func appDisappeared(_ notification: Notification){
           

    }
    
    func checkAndDownloadChatInfo(completed: @escaping () -> ()){
        if chatInfo.uids.isEmpty {
                        
            Firestore.firestore().collection("Chats").document(chatInfo.chatID).getDocument(completion: { doc, error in
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                    guard doc?.exists ?? false else{return}
                    let timestamp = (doc?["Timestamp"] as? Timestamp)?.dateValue()
                    let activeTime = (doc?["Active"] as? Timestamp)?.dateValue()
                    let uids = (doc?["Members"] as? [String] ?? [])?.sortedAlphabet()
                    let uid = uids?.filter({$0 != pUserInfo.uid}).first
                    let muteList = doc?["Muted"] as? [String] ?? []

                    self.downloadUserInfo(uid: uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postNotifs, postCount, followersCount, followingCount, verified in
                        
                        let userInfo = UserInfo(uid: uid, dp: imgData, dpID: dpUID, username: username, fullName: fullName, bio: bio, notifID: notifID, userFollowing: userFollowing, userLiked: [], followerCount: followersCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking, profileLink: nil, verified: verified)
                        
                        let gc = GroupChat(uids: uids, chatID: self.chatInfo.chatID, userImageIDs: [], timestamp: timestamp, isActive: true, index: 0, activeTime: activeTime, activeTimeDiff: nil, timestampDiff: nil, lastText: nil, chatName: nil, displayUserInfo: userInfo, didMute: muteList.contains(pUserInfo.uid ?? ""))
                        gc.chatName = userInfo.fullName
                        self.chatInfo = gc
                        completed()
                    })
                }
            })
        }
        else{
            completed()
        }
    }
    
    @IBOutlet weak var openPhotosBtn: UIButton!
    
    @IBOutlet weak var openCameraBtn: UIButton!
    
    @IBAction func sendText(_ sender: UIButton){
        
        checkToCreateChat {
            self.refreshLists(userUID: pUserInfo.uid ?? ""){
                
                Analytics.logEvent("send_text", parameters: [
                    "name": "Send Text",
                    "full_text": "User sent a text"
                ])
                
                let rawDate = Date()
                print(rawDate)
                
                let date = rawDate.currentDate(asString: true, dateToUse: rawDate, toFirestoreFormat: true).0
                
                var message: TextMessage!
                
                let newMessageRef: DocumentReference! = Firestore.firestore().collection("Chats").document(self.chatInfo.chatID).collection("Messages").document()

                if !(self.textView.text?.isEmpty ?? false){
                    let text = "\(self.textView.text ?? "")".prepared()
                            
                    self.textView.text.removeAll()
                    self.textViewDidChange(self.textView)

                    let new = date?.getDayOfWeek(date ?? "")
                    
                    message = TextMessage(uid: pUserInfo.uid ?? "", message: text, textID: newMessageRef.documentID, isPic: false, dp: UIImage(data: pUserInfo.dp ?? defaultDP!), fullname: pUserInfo.fullName, username: pUserInfo.username, timestamp: date ?? "", dpID: pUserInfo.dpID ?? "", index: nil, messageImg: nil, aspectRatio: nil, estimatedHeight: nil, date: new, rawDate: rawDate)
                    
                }
                else{
                    
                    if !self.cameraRollCollectionView.isHidden{
                        self.configurePhotos(self.openPhotosBtn)
                    }
                    
                    var selectedImage: UIImage!

                    if sender.accessibilityIdentifier == "CameraSendBtn"{
                        selectedImage = self.cameraView.selectedImage
                    }
                    else if sender.accessibilityIdentifier == "LibrarySendBtn"{
                        selectedImage = self.cameraRollCollectionView.selectedImage
                    }
                    
                    if let img = selectedImage{
                        message = TextMessage(uid: pUserInfo.uid ?? "", message: nil, textID: newMessageRef.documentID, isPic: true, dp: UIImage(data: pUserInfo.dp!), fullname: pUserInfo.fullName, username: pUserInfo.fullName, timestamp: date ?? "", dpID: pUserInfo.dpID, index: nil, messageImg: img, aspectRatio: img.size.height / img.size.width, estimatedHeight: nil, date: date?.getDayOfWeek(date ?? ""), rawDate: rawDate)
                    }
                }
                
                guard message != nil else{return}
                
                self.chatInfo.timestamp = rawDate
                message?.readBy = [pUserInfo.uid ?? ""]
                self.insertRow(message: message){
                                    
                    if let index = self.allMessages[0].firstIndex(where: {$0.textID == message?.textID}){
                        self.tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            
                            if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)){
                                
                                var data = [
                                    "Timestamp" : date ?? "",
                                    "UID" : pUserInfo.uid ?? "",
                                    "Deleted" : false,
                                    "Raw_Timestamp" : rawDate,
                                    "Cell Height" : cell.frame.height,
                                    "readBy" : [pUserInfo.uid ?? ""]
                                    ] as [String : Any]
                                
                                switch message.isPic{
                                case true:
                                    
                                    data["Aspect Ratio"] = message?.aspectRatio
                                    data["isPic"] = true
                                    
                                    if let c = cell as? PicMessageCell{
                                        UIView.animate(withDuration: 0.8, delay: 0, options: [.autoreverse, .repeat], animations: {
                                            c.textImgView.alpha = 0.60
                                        }, completion: nil)
                                        self.uploadPhoto(image: message.messageImg!, picID: newMessageRef.documentID, completed: { success in
                                            if success{
                                                self.uploadText(newMessageRef: newMessageRef, data: data, cell: c, rawDate: rawDate)
                                            }
                                        })
                                    }
                                default:
                                    if let text = message?.message{
                                        data["Message"] = text
                                        data["isPic"] = false
                                    }
                                    if let c = cell as? TextMessageCell{
                                        
                                        UIView.animate(withDuration: 0.8, delay: 0, options: [.autoreverse, .repeat], animations: {
                                            c.textViewBack.alpha = 0.60
                                        }, completion: nil)
                                        self.uploadText(newMessageRef: newMessageRef, data: data, cell: c, rawDate: rawDate)
                                    }
                                }
                                self.allMessages[0][index].textID = newMessageRef.documentID
                                self.allMessages[0][index].estimatedHeight = cell.frame.height
                            }
                        }
                    }
                }
            }
        }
    }
    
    func uploadText(newMessageRef: DocumentReference, data: [String : Any], cell: UITableViewCell, rawDate: Date){
        let batch = Firestore.firestore().batch()
        let chatRef = Firestore.firestore().collection("Chats").document(chatInfo.chatID)
                
        batch.setData(data, forDocument: newMessageRef)
        let uids = chatInfo.uids.sortedAlphabet().filter({!(pUserInfo.usersBlocking.contains($0))})
        batch.updateData(["Timestamp" : rawDate, "Members" : uids.sortedAlphabet()], forDocument: chatRef)
        
        batch.commit { (error) in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                if let textImgView = (cell as? PicMessageCell)?.textImgView{
                    textImgView.layer.removeAllAnimations()
                    textImgView.alpha = 1.0
                }
                
                if let textMsgView = (cell as? TextMessageCell)?.textViewBack{
                    textMsgView.layer.removeAllAnimations()
                    textMsgView.alpha = 1.0
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if allMessages[section].first?.uid == pUserInfo.uid, allMessages[section].first?.readBy.contains(where: {$0 != pUserInfo.uid}) ?? false{
            return 20
        }
        return 0

    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20))
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: view.frame.width - 20, height: view.frame.height))
        view.addSubview(label)
        guard allMessages[section].first?.uid == pUserInfo.uid, allMessages[section].first?.readBy.contains(where: {$0 != pUserInfo.uid}) ?? false else{return view}
        label.font = UIFont(name: "NexaW01-Regular", size: 12)
        label.textColor = .tertiaryLabel
        label.setSeenLbl(text: "Seen ")
        label.textAlignment = .right
        view.transform = CGAffineTransform(scaleX: 1, y: -1)

        return view
    }
    
    func insertRow(message: TextMessage, completed: @escaping () -> ()){
        
        switch self.allMessages.indices.contains(0){
            
        case true:
            if self.allMessages[0].first?.date != message.date{
                fallthrough
            }
            else{
                self.allMessages[0].insert(message, at: 0)
                self.tableView.performBatchUpdates({
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                }, completion: { finished in
                    if finished{
                        completed()
                    }
                })
            }
        case false:
            
            self.allMessages.insert([message], at: 0)
            self.tableView.performBatchUpdates({
                self.tableView.insertSections(IndexSet(integer: 0), with: .fade)
            }, completion: { finished in
                if finished{
                    completed()
                }
            })
        }
    }

        
    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = self.view.safeAreaInsets.bottom

        if textView.isFirstResponder{
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    let keyboardHeight = keyboardRectangle.height
                    self.keyBoardHeight = keyboardHeight
                    UIView.animate(withDuration: 0.2, animations: {
                        self.bottomBar.transform = CGAffineTransform(translationX: 0, y: -(keyboardHeight - bottomPadding))
                        
                        if self.tableView.contentInset.top == 0{
                            self.tableView.contentOffset.y -= keyboardHeight - bottomPadding
                        }
                        self.tableView.contentInset.top = keyboardHeight - bottomPadding
                        self.tableView.verticalScrollIndicatorInsets.top = keyboardHeight - bottomPadding
                        
                    }, completion: { finished in
                        if finished{}
                    })
                }
            }
        }
    }
    
    lazy var cameraRollCollectionView: PhotosView = {
        
        let y = view.frame.midY
        let collectionView = PhotosView.init(frame: CGRect(x: 0, y: view.frame.height - y, width: view.frame.width, height: y))
        
        view.addSubview(collectionView)
        collectionView.isHidden = true

        return collectionView
    }()
    
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCell", for: indexPath) as? PhotosCell
        cell?.photoImageView.clipsToBounds = true
        cell?.photoImageView.image = nil
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.version = .current
        
        if let layout = collectionView.collectionViewLayout as? CollectionViewLayout{
            self.downloadImage(options: options, targetSize: CGSize(width: layout.itemSize.width * 2, height: layout.itemSize.height * 2), asset: self.images[indexPath.item], completed: { image in
                DispatchQueue.main.async {
                    cell?.photoImageView.image = image
                }
            })
        }
        
        return cell!
    }
    
    func downloadImage(options: PHImageRequestOptions?, targetSize: CGSize, asset: PHAsset, completed: @escaping (UIImage?) -> ()){
        
        let manager = PHImageManager.default()
        
        manager.requestImage(for: asset,
                         
        targetSize: targetSize,
        contentMode: .aspectFill,
        
        options: options) { (result, _) in
            completed(result)
        }
    }

    fileprivate func uploadPhoto(image: UIImage, picID: String, completed: @escaping (Bool) -> ()){
        
        
        let ref = Storage.storage().reference().child("Chats/CHAT-" + self.chatInfo.chatID + "/" + "Messages" + "/" + "TEXT-" + picID + ".jpg")
        
        if let uploadData = image.jpegData(compressionQuality: 0.6){
            ref.putData(uploadData, metadata: nil, completion:{ (metaData, error) in
                if error != nil{
                    print(error?.localizedDescription ?? "no error")
                    completed(false)
                    return
                }else{
                    completed(true)
                    return
                }
            })
        }
    }
    
    fileprivate var keyBoardHeight: CGFloat = 0
    
    
    @IBAction func openCamera(_ sender: UIButton) {
        //self.animateOptionMenuCameraRollButton(didOpen: false)
        cameraView.isHidden = true
        UIView.setAnimationsEnabled(false)
        textView.resignFirstResponder()
        UIView.setAnimationsEnabled(true)
        cameraRollCollectionView.hidePhotosCollectionView {
            openPhotosBtn.tintColor = UIColor(named: "LoadingColor")
            cameraView.isHidden = false
            let cameraBtnMaxY = bottomBar.frame.maxY
            cameraView.openCameraAnimate(backgroundView: view, viewToCarry: bottomBar, viewMaxY: cameraBtnMaxY){
                self.bottomBar.isHidden = true
            }
        }
    }

    lazy var cameraView: CameraView = {
        
        let view = CameraView.init(frame: CGRect(x: 0, y: self.bottomBar.frame.maxY, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(view)
        view.dismissBtn.addTarget(self, action: #selector(closeCamera(_:)), for: [.touchUpInside, .touchDragExit])
     
        view.bottomBar.frame.size.height = view.bottomBar.frame.height + self.view.safeAreaInsets.bottom
        view.bottomBar.frame.origin.y = view.frame.height - (view.bottomBar.frame.height)
        
        
        return view
    }()
    
    
    @objc func closeCamera(_ sender: Any?){
        
        self.cameraView.hideCameraAnimate(viewToCarry: bottomBar) {
            self.cameraView.resetDisplayImage()
        }
    }
    
    
    @IBAction fileprivate func showCameraRoll(_ sender: UIButton){
        
        configurePhotos(sender)
    }
    
    func showCamRoll(sender: UIButton?){
        let y = view.frame.midY
        let btnMaxY = bottomBar.frame.maxY
        bottomBar.transform = CGAffineTransform(translationX: 0, y: (y - btnMaxY))
        cameraRollCollectionView.showCameraRollAnimate(completed: { openedRoll in
            if !openedRoll{
                self.cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: self.view, tableView: self.tableView){
                }
            }
        })
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if !self.cameraRollCollectionView.isHidden{
            self.cameraRollCollectionView.hidePhotosCollectionView {
                self.openPhotosBtn.tintColor = UIColor(named: "LoadingColor")
            }
        }
    }
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            
            UIView.animate(withDuration: 0.2, animations: {
                self.bottomBar.transform = CGAffineTransform.identity
                self.tableView.contentInset.top = 0
                self.tableView.verticalScrollIndicatorInsets.top = 0
            })
        }
    }
    
    func group(messages: [TextMessage], initial: Bool, completed: @escaping () -> ()){
        

        let grouped = Dictionary(grouping: messages, by: {(element) -> String in
            return (element.date ?? "")
        })

        let sorted = grouped.keys.sorted(by: >)
        
        for (ind, key) in sorted.enumerated(){
        
            let values = grouped[key]
            
            if let messageIndex = self.allMessages.firstIndex(where: {$0.contains(where: {$0.date == key})}){
                                  
                for k in values ?? []{
                    self.allMessages[messageIndex].append(k)
                    
                    if initial{
                        if ind == sorted.count - 1{
                            self.tableView.reloadData()
                            completed()
                        }
                    }
                    else{

                        self.tableView.performBatchUpdates({
                            self.tableView.insertRows(at: [IndexPath(row: self.allMessages[messageIndex].count - 1, section: messageIndex)], with: .none)
                        }, completion: { finished in
                            if finished{
                                if ind == sorted.count - 1{
                                    completed()
                                }
                            }
                        })
                    }
                }
            }
            else{
                self.allMessages.append(values ?? [])
                if initial{
                    if ind == sorted.count - 1{
                        self.tableView.reloadData()
                        completed()
                    }
                }
                else{
                    self.tableView.performBatchUpdates({
                    self.tableView.insertSections(IndexSet(integer: self.allMessages.count - 1), with: .none)
                    }, completion: { finished in
                        if finished{
                            if ind == sorted.count - 1{
                                completed()
                            }
                        }
                    })
                }
            }
        }
    }

    
    func load(fromInterval: String, completed: @escaping (Query, Bool) -> ()){
      

        let ref = Firestore.firestore().collection("Chats").document(chatInfo.chatID).collection("Messages")
        
        var query: Query!
        
        if fromInterval == ""{
            query = ref.whereField("Timestamp", isLessThanOrEqualTo: Date().currentDate(asString: true, dateToUse: Date().adding(hours: 1), toFirestoreFormat: true).0 ?? "").order(by: "Timestamp", descending: true).limit(to: 15)
        }
        else{
            query = ref.whereField("Timestamp", isLessThan: fromInterval).order(by: "Timestamp", descending: true).limit(to: 15)
        }
        
        query.getDocuments(completion: { snaps, error in
            
            //self.loadingHeaderView?.cp.isHidden = true

            if error != nil{
                completed(query, true)
                print(error?.localizedDescription ?? "")
                return
            }
            else{
                if let docs = snaps?.documents{
                    
                    if docs.isEmpty{
                        completed(query, true)
                        
                        UIView.animate(withDuration: 0.2, animations: {
                            self.tableView.alpha = 1.0
                        })
                    }
                    else{
                        var messages: [TextMessage] = [TextMessage]()
                        
                        for snapInfo in docs{
                            
                            let msg = snapInfo["Message"] as? String
                            guard let uid = snapInfo["UID"] as? String else{continue}
                            guard let timestamp = snapInfo["Timestamp"] as? String else{
                                
                                continue}
                            
                            let isPic = snapInfo["isPic"] as? Bool
                            let aspectRatio = snapInfo["Aspect Ratio"] as? CGFloat
                            let estimatedHeight = snapInfo["Cell Height"] as? CGFloat
                            let date = timestamp.getDayOfWeek(timestamp)
                            let rawDate = (snapInfo["Raw_Timestamp"] as? Timestamp)?.dateValue()
                            let deleted = snapInfo["Deleted"] as? Bool

                            let didSee = snapInfo["readBy"] as? [String] ?? []

                            
                            if let section = self.allMessages.first(where: {$0.contains(where: {$0.textID == snapInfo.documentID})}){
                                
                                if let same = section.first(where: {$0.textID == snapInfo.documentID}){
                                    same.uid = uid
                                    same.isPic = isPic ?? false
                                    same.aspectRatio = aspectRatio
                                    same.timestamp = timestamp
                                    same.message = msg
                                    same.textID = snapInfo.documentID
                                    same.estimatedHeight = estimatedHeight
                                    same.date = date
                                    same.removed = deleted
                                    same.readBy = didSee
                                }
                            }
                            else{
                                
                                let message = TextMessage(uid: uid, message: msg, textID: snapInfo.documentID, isPic: isPic ?? false, dp: nil, fullname: nil, username: nil, timestamp: timestamp, dpID: nil, index: nil, messageImg: nil, aspectRatio: aspectRatio, estimatedHeight: estimatedHeight, date: date, rawDate: rawDate)
                                message.removed = deleted
                                message.readBy = didSee
                                messages.append(message)
                                
                            }
                        }
                        //REMAINING SECTION APPENDED
                       
                        self.group(messages: messages, initial: true){
                            completed(query, false)
                        }
                        if fromInterval.isEmpty{
                            UIView.animate(withDuration: 0.2, animations: {
                                self.tableView.alpha = 1.0
                            })
                        }
                    }
                }
            }
        })
    }
    
    var listeners: [ListenerRegistration?]? = [ListenerRegistration?]()
    
    func loadMessages(fromInterval: String, query: Query, completed: @escaping () -> ()){
        
        let listener = query.addSnapshotListener(includeMetadataChanges: false, listener: { snapshot, error in
            
            if error != nil{
                print(error?.localizedDescription ?? "")
                completed()
            }
            else{
                if let snaps = snapshot?.documentChanges{
                    if snaps.isEmpty{
                        completed()
                    }
                    else{
                        print(snapshot?.metadata.isFromCache ?? false)
                        
                        completed()
                        var messages: [TextMessage] = [TextMessage]()
                        
                        for snap in snaps{ // LOADED DOCUMENTS FROM \(snapDocuments)
                            let snapInfo = snap.document
                            let msg = snapInfo["Message"] as? String
                            guard let uid = snapInfo["UID"] as? String else{continue}
                            let rawDate = (snapInfo["Raw_Timestamp"] as? Timestamp)?.dateValue()
                            guard let timestamp = snapInfo["Timestamp"] as? String else{continue}
                            let deleted = snapInfo["Deleted"] as? Bool
                            let isPic = snapInfo["isPic"] as? Bool
                            let aspectRatio = snapInfo["Aspect Ratio"] as? CGFloat
                            let estimatedHeight = snapInfo["Cell Height"] as? CGFloat
                            let date = timestamp.getDayOfWeek(timestamp)
                            let didSee = snapInfo["readBy"] as? [String] ?? []
  
                            if snap.type == .added{
                                
                                

                                if let section = self.allMessages.first(where: {$0.contains(where: {$0.textID == snapInfo.documentID})}){
                                    
                                    if let same = section.first(where: {$0.textID == snapInfo.documentID}){
                                        same.uid = uid
                                        same.isPic = isPic ?? false
                                        same.aspectRatio = aspectRatio
                                        same.timestamp = timestamp
                                        same.message = msg
                                        same.textID = snapInfo.documentID
                                        same.estimatedHeight = estimatedHeight
                                        same.date = date
                                        same.removed = deleted
                                        same.readBy = didSee
                                    }
                                }
                                else{
                                    let message = TextMessage(uid: uid, message: msg, textID: snapInfo.documentID, isPic: isPic ?? false, dp: nil, fullname: nil, username: nil, timestamp: timestamp, dpID: nil, index: nil, messageImg: nil, aspectRatio: aspectRatio, estimatedHeight: estimatedHeight, date: date, rawDate: rawDate)
                                    message.removed = deleted
                                    message.readBy = didSee
                                    messages.append(message)
                                    
                                    if fromInterval.isEmpty{
                                        if self.allMessages.isEmpty{
                                            self.allMessages.insert(messages, at: 0)
                                            self.tableView.performBatchUpdates({
                                                self.tableView.insertSections(IndexSet(integer: 0), with: .none)
                                            }, completion: nil)
                                        }
                                        else{
                                            if self.allMessages[0].contains(where: {$0.date == message.date}){
                                                self.allMessages[0].insert(message, at: 0)
                                                self.checkToMoveDpDown()
                                                self.tableView.performBatchUpdates({
                                                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                                                }, completion: nil)
                                            
                                            }
                                            else{
                                                self.allMessages.insert(messages, at: 0)
                                                self.tableView.performBatchUpdates({
                                                    self.tableView.insertSections(IndexSet(integer: 0), with: .none)
                                                }, completion: nil)
                                            }
                                        }
                                               
                                        if message.uid == pUserInfo.uid{
                                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                                        }
                                        else{
                                            if self.tableView.indexPathsForVisibleRows?.contains(IndexPath(row: 0, section: 0)) ?? false{
                                                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                                            }
                                        }
                                    }
                                }
                            }
                            else if snap.type == .modified{
                                
                                if let section = self.allMessages.firstIndex(where: {$0.contains(where: {$0.textID == snap.document.documentID})}){
                                    if let index = self.allMessages[section].firstIndex(where: {$0.textID == snap.document.documentID}), !(index == 0 && section == 0 && uid == pUserInfo.uid && !(deleted ?? false)){
                                        self.allMessages[section][index].removed = deleted
                                        self.allMessages[section][index].readBy = didSee
                                        self.tableView.performBatchUpdates({
                                            self.tableView.reloadRows(at: [IndexPath(row: index, section: section)], with: .fade)
                                        }, completion: nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        self.listeners?.append(listener)
    }
    
    func showZoomableView(sender: UITapGestureRecognizer){
        guard let imgView = sender.view as? UIImageView else{return}
        zoomableView.isHidden = false
        textView.resignFirstResponder()
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.openedView = imgView
        let imageView = zoomableView.subviews.first as? UIImageView
        imageView?.frame = imgView.globalFrame!
        imageView?.contentMode = .scaleAspectFill
        imageView?.image = nil
        imageView?.image = imgView.image
        zoomableView.alpha = 0.0
        zoomableView.backgroundColor = .clear
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        UIView.animate(withDuration: 0.2, animations: {
            self.zoomableView.alpha = 1.0
            imageView?.frame = CGRect(x: 0, y: 0, width: self.zoomableView.frame.width, height: self.zoomableView.frame.height)
            imageView?.contentMode = .scaleAspectFit
        }, completion: { finished in
            if finished{
                self.zoomableView.backgroundColor = UIColor.black.withAlphaComponent(0.90)
            }
        })
    }
    
    var openedView: UIView!
    
    @objc func hideZoomableView(_ sender: Any){
        zoomableView.alpha = 1.0
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        let imageView = zoomableView.subviews.first as? UIImageView
        zoomableView.backgroundColor = .clear
        UIView.animate(withDuration: 0.2, animations: {
            imageView?.contentMode = .scaleAspectFill
            imageView?.frame = self.openedView.globalFrame!
            self.zoomableView.alpha = 0.0
        }, completion: { finished in
            if finished{
                self.openedView = nil
                self.zoomableView.isHidden = true
            }
        })
    }
    
    
    @objc func handleZoom(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            if gesture.scale >= 1 {
                let scale = gesture.scale
                gesture.view!.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
              gesture.view!.transform = .identity
            }) { _ in}
        }
    }
    
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            let translation = gesture.translation(in: self.zoomableView)
            gesture.view?.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
            gesture.setTranslation(.zero, in: self.zoomableView)
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                gesture.view?.center = self.zoomableView.center
                gesture.setTranslation(.zero, in: self.zoomableView)
            }) { _ in}
            break
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    lazy var swiper: UIPanGestureRecognizer = {
       
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(checkSwipe(_:)))
        return gesture
    }()
    
    @objc func checkSwipe(_ sender: UIPanGestureRecognizer){
        
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: zoomableView)
            if let view = sender.view{
                view.center.y += translation.y
                sender.setTranslation(CGPoint.zero, in: zoomableView)
            }
        }
        if sender.state == .ended{
            if self.zoomableView.frame.origin.y >= 100{
                
                print(self.zoomableView.frame.origin.y)
                //Switch for other app
                /*
                if let vc = self.getViewController(){
                    (vc as? EditProfileVC)?.hideProfileCam{}
                    (vc as? DesignViewController)?.closeCamera(nil)
                    (vc as? CommentsVC)?.closeCamera(nil)
                    (vc as? ChatVC)?.closeCamera(nil)
                }
                */
                hideZoomableView(sender)
                self.zoomableView.frame.origin.y = 0
            }
            else{
                UIView.animate(withDuration: 0.2, animations: {
                    self.zoomableView.frame.origin.y = 0
                }, completion: {finished in
                    if finished{
                        sender.setTranslation(CGPoint.zero, in: self.zoomableView)
                    }
                })
            }
        }
    }
    
    lazy var zoomableView: UIView = {
        
        let view = UIView.init(frame: self.view.frame)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.90)
        let tapper = UITapGestureRecognizer.init(target: self, action: #selector(hideZoomableView(_:)))
        view.addGestureRecognizer(tapper)
        view.addGestureRecognizer(swiper)

        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = self
        pinch.delegate = self
        imageView.addGestureRecognizer(pinch)
        imageView.addGestureRecognizer(pan)
        view.addSubview(imageView)
        
        let doneZoomingBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        doneZoomingBtn.setImage(UIImage(nameOrSystemName: "xmark", systemPointSize: 18, iconSize: 9), for: .normal)
        doneZoomingBtn.tintColor = UIColor(named: "LoadingColor")
        doneZoomingBtn.frame.origin.y = self.view.safeAreaInsets.top + doneZoomingBtn.frame.height
        doneZoomingBtn.addTarget(self, action: #selector(hideZoomableView(_:)), for: .touchUpInside)
        doneZoomingBtn.setRadiusWithShadow()
        
        let saveMenuBtn = UIButton(frame: CGRect(x: view.frame.maxX - 50, y: 0, width: 50, height: 50))
        saveMenuBtn.setImage(UIImage(nameOrSystemName: "ellipsis", systemPointSize: 18, iconSize: 9), for: .normal)
        saveMenuBtn.tintColor = UIColor(named: "LoadingColor")
        saveMenuBtn.frame.origin.y = self.view.safeAreaInsets.top + doneZoomingBtn.frame.height
        saveMenuBtn.addTarget(self, action: #selector(showFullImageMenu(_:)), for: .touchUpInside)
        saveMenuBtn.setRadiusWithShadow()
        
        view.addSubview(doneZoomingBtn)
        view.addSubview(saveMenuBtn)

        return view
    }()
    
    @objc func showFullImageMenu(_ sender: UIButton){

        let popup = PopupDialog(title: nil, message: nil, image: nil, buttonAlignment: .vertical, transitionStyle: .bounceUp, preferredWidth: self.view.frame.width, tapGestureDismissal: true, panGestureDismissal: true, hideStatusBar: true, completion: nil)
        let dialogAppearance = PopupDialogDefaultView.appearance()
        
        dialogAppearance.backgroundColor = .secondarySystemBackground
        // Create buttons
        
        // This button will not the dismiss the dialog
        let button = DefaultButton(title: "SAVE IMAGE", dismissOnTap: false) {
            let imageView = self.zoomableView.subviews.first as? UIImageView
            imageView?.image?.saveToPhotos(completion: { success in
                DispatchQueue.main.async {
                    popup.shake()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        popup.dismiss()
                    }
                }
            })
        }
        let cancelBtn = CancelButton(title: "DONE", dismissOnTap: true) {}
        cancelBtn.titleFont = UIFont(name: "NexaW01-Heavy", size: 16)
        cancelBtn.backgroundColor = .tertiarySystemBackground
        cancelBtn.setTitleColor(UIColor.secondaryLabel, for: .normal)
        
        button.titleFont = UIFont(name: "NexaW01-Heavy", size: 16)
        button.backgroundColor = .tertiarySystemBackground
        button.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        
        popup.addButtons([button, cancelBtn])
     
        self.present(popup, animated: true, completion: {
            
        })
        
    }

    func readMessage(message: TextMessage!, indexPath: IndexPath){
        
        guard let uid = pUserInfo.uid else{return}
        if !(message.readBy.contains(uid)), indexPath == IndexPath(row: 0, section: 0){
            message.readBy.append(uid)
            let data = [
                "readBy" : FieldValue.arrayUnion([uid])
            ]
            Firestore.firestore().collection("Chats/\(chatInfo.chatID)/Messages").document(message.textID).updateData(data, completion: { error in
                
            })
        }
        DispatchQueue(label: "notifs").async {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["Text-\(self.chatInfo.chatID)"])

            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    

    func unsendMessage(message: TextMessage){
        
        let batch = Firestore.firestore().batch()
        
        let ref = Firestore.firestore().collection("Chats/\(chatInfo.chatID)/Messages").document(message.textID)
        let chatRef = Firestore.firestore().collection("Chats").document(chatInfo.chatID)
        
        batch.updateData(["Deleted" : true], forDocument: ref)
        batch.updateData(["Timestamp" : Date()], forDocument: chatRef)
        
        batch.commit(completion: { error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                return
            }
        })
    }

    
    func checkToMoveDpDown(){
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)){
            if let imageView = (cell as? TextMessageCell)?.userImgView ?? (cell as? PicMessageCell)?.userImgView{
                cell.addUserImage(section: 0, dp: imageView, textMsg: self.allMessages[0][1], chatVC: self)
            }
        }
    }

    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView is UITableView{
            if(velocity.y < 0) {
                print("Hide")
                
            } else {
                print("Unhide")
                if self.textView.isFirstResponder{
                    self.textView.resignFirstResponder()
                }
                if !self.cameraRollCollectionView.isHidden{
                    configurePhotos(openPhotosBtn)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        
        let visibleCells = self.tableView.indexPathsForVisibleRows
        for (section, _) in self.allMessages.enumerated(){
            for (index, _) in self.allMessages[section].enumerated(){
                if !(visibleCells?.contains(IndexPath(row: index, section: section)) ?? true){
                    self.allMessages[section][index].dp = nil
                }
            }
        }
        DispatchQueue.global(qos: .background).sync {
            cache.clearMemory()
        }
    }
    

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height - 20){
            let last = self.allMessages.last?.last
            if let interval = last?.timestamp{
                if !self.isLoadingTexts{
                    self.isLoadingTexts = true
                    //self.loadingHeaderView?.cp.isHidden = false
                    self.load(fromInterval: interval){[weak self] query, isEmpty  in
                        if isEmpty{
                            //for spinner in self?.loadingHeaderView?.subviews.filter({$0.isKind(of: MapSpinnerView.self)}) ?? []{
                                //spinner.removeFromSuperview()
                            //}
                        }
                        else{
                            self?.isLoadingTexts = false
                        }
                    }
                }
            }
        }
    }
 
    
     
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
      
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(listeners?.count ?? 0)
        print(self.allMessages.count)
        if self.isMovingFromParent{
            for listener in listeners ?? []{
                listener?.remove()
            }
        }
    }
    
    

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.allMessages.count
    }
    
    func dateLblView(section: Int) -> UIView{
        
        let aview = UIView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
        let sView = UIView(frame: aview.frame)
        let label = UIButton.init(frame: sView.frame)
        sView.bounds = aview.bounds
        label.bounds = sView.bounds
        label.addTarget(self, action: #selector(scrollToSection(_:)), for: .touchUpInside)
        label.tag = section
        sView.addSubview(label)
        aview.addSubview(sView)
        let m = allMessages[section].compactMap({$0.date}).first
        
        let attributes:[NSAttributedString.Key:Any] = [
            NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel,
            NSAttributedString.Key.font : UIFont(name: "NexaW01-Heavy", size: 11)!
        ]
        label.transform = CGAffineTransform(scaleX: 1, y: -1)
        let g = getDateDiff(start: (m?.getMessageDateFromString(timezone: TimeZone.current)) ?? Date(), end: Date())
        var title: String!
        if g == 0{
            title = "Today"
        }
        else if g == 1{
            title = "Yesterday"
        }
        else{
            title = m ?? ""
        }
        label.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        let size = label.sizeThatFits(label.frame.size)
        label.frame.size.width = size.width + 15
        label.frame.size.height = size.height - 5
        sView.frame.size = label.frame.size
        label.center = sView.center
        sView.center = aview.center
        sView.layer.cornerRadius = sView.frame.height / 2
        sView.clipsToBounds = true
        sView.addBackgroundBlur(blurEffect: UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial))
        return aview
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return dateLblView(section: section)
    }
    
    
    
    @objc func scrollToSection(_ sender: UIButton){
        
        if let sectionHeader = sender.superview?.superview{
            
            let section = sectionHeader.tag
            let messages = allMessages[section]
            
            self.tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: section), at: .none, animated: true)
        }
    }

    func getDateDiff(start: Date, end: Date) -> Int  {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([Calendar.Component.day], from: start, to: end)
        let seconds = dateComponents.day
        return Int(seconds!)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allMessages[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print(indexPath.row)
        print(indexPath.section)
        print(self.allMessages.count)
        
        guard allMessages.indices.contains(indexPath.section), allMessages[indexPath.section].indices.contains(indexPath.row) else{return UITableViewCell()}
        let textMsg = allMessages[indexPath.section][indexPath.row]
        
        readMessage(message: textMsg, indexPath: indexPath)
        
        
        if textMsg.removed ?? false{
            let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
            cell.textLabel?.text = "message was unsent"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.font = UIFont(name: "NexaW01-Regular", size: 12)
            if textMsg.uid == pUserInfo.uid{
                cell.textLabel?.textAlignment = .right
            }
            else{
                cell.textLabel?.textAlignment = .left
            }
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            return cell
        }
        else{
            if textMsg.isPic{
                let cell = tableView.setPicMessage(indexPath: indexPath, textMsg: textMsg, chatVC: self)
                return cell
            }
            else{
                let cell = tableView.setTextMessage(indexPath: indexPath, textMsg: textMsg, chatVC: self)
                return cell
            }
        }
    }
    var placeholderLabel = UILabel()

    func setPlaceholder(textView: UITextView, textColor: UIColor?){
        
        
        placeholderLabel.text = "Say something..."
        placeholderLabel.font = UIFont.systemFont(ofSize: 15.0)
        placeholderLabel.sizeToFit()
        placeholderLabel.backgroundColor = UIColor.clear
        placeholderLabel.textColor = textColor
        
        if !textView.subviews.contains(placeholderLabel){
            textView.addSubview(placeholderLabel)
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor,  constant: 5).isActive = true
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        
    }
    
    var initialWidth = CGFloat()
    var initialHeight = CGFloat()
    var previousHeight = CGFloat()
    
    func textViewDidChange(_ textView: UITextView) {
        
        print("changed text")
        
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        let check = (self.view.frame.height - self.view.frame.height / 2) - (textView.sizeThatFits(CGSize(width: initialWidth, height: CGFloat.greatestFiniteMagnitude)).height)
        print(check)
        if check > 100{
            textView.isScrollEnabled = false
            let size = textView.sizeThatFits(CGSize(width: initialWidth, height: CGFloat.greatestFiniteMagnitude)).height
            self.bottomBarHeight.constant = size + 50
            DispatchQueue.main.async {
                if self.bottomBarHeight.constant > self.previousHeight + 50{
                    let difference = self.bottomBarHeight.constant - (self.previousHeight - 50)
                    self.tableView.contentOffset.y -= difference
                }
                else if self.bottomBarHeight.constant < self.previousHeight + 50{
                    let difference = (self.previousHeight + 50) - self.bottomBarHeight.constant
                    self.tableView.contentOffset.y += difference
                }
            }
            self.previousHeight = self.bottomBarHeight.constant - 50
        }
        else{
            let string = textView.text.replacingOccurrences(of: " ", with: "")
            if string.count > 1000{
                textView.text.removeLast(textView.text.count - 1000)
            }
            if !textView.isScrollEnabled{
                DispatchQueue.main.async {
                    textView.isScrollEnabled = true
                }
            }
        }
        
        bottomBar.setNeedsLayout()
        bottomBar.layoutIfNeeded()
        
        if self.textView.text.isEmpty{
            if self.openPhotosBtn.isHidden{
                self.openPhotosBtn.isHidden = false
                self.sendTextBtn.isHidden = true

                self.openPhotosBtn.alpha = 0.0
                UIView.animate(withDuration: 0.25, animations: {
                    self.openPhotosBtn.alpha = 1.0
                }, completion: { finished in
                    if finished{
                    }
                })
            }

        }
        else{

            if self.sendTextBtn.isHidden{
                self.sendTextBtn.isHidden = false
                self.openPhotosBtn.isHidden = true
                self.sendTextBtn.alpha = 0.0
                UIView.animate(withDuration: 0.25, animations: {
                    self.sendTextBtn.alpha = 1.0
                }, completion: { finished in
                    if finished{
                    }
                })
            }
        }
        bottomBar.setNeedsLayout()
        bottomBar.layoutIfNeeded()
    }
    
    var isStatusBarHidden = false
    
    override var prefersStatusBarHidden: Bool{
        return isStatusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //print("Estimate: \(messages[indexPath.row].estimatedHeight ?? 0)")
        //print("Actual: \(cell.frame.height)")
      
        
    }
    
    @objc func usePhoto(_ sender: UIButton){
        
        if !self.cameraView.isHidden{
            self.cameraView.hideCameraAnimate(viewToCarry: bottomBar, completed: {
                self.cameraView.resetDisplayImage()
                self.sendText(sender)
            })
        }
        else if !self.cameraRollCollectionView.isHidden{
            sendText(sender)
        }
    }
    
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let k = self.allMessages[indexPath.section][indexPath.row].estimatedHeight
            else{
                return UITableView.automaticDimension}
        return k
    }
    
   
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let friendVC = segue.destination as? FriendVC{
            friendVC.friendInfo = selectedUser
        }
    }
    

}

extension UIScrollView {
    func scrollsToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: contentOffset.x,
                                   y: contentSize.height - bounds.height + adjustedContentInset.top)
        setContentOffset(bottomOffset, animated: animated)
    }
}

extension UIScrollView {

    var scrolledToTop: Bool {
        let topEdge = 0 - contentInset.top
        print("CO: \(contentOffset.y)")
        print("T: \(topEdge + self.bounds.height)")
        return contentOffset.y == topEdge
    }

    var scrolledToBottom: Bool {
        let bottomEdge = contentSize.height + contentInset.top - bounds.height
        return contentOffset.y >= bottomEdge
    }

}

extension UIView{
    
    /*
    func addBackgroundBlur(blurEffect: UIBlurEffect){
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(blurEffectView, at: 0)
    }
*/
}


extension UIViewController{
    
    func presentCameraSettings(completed: @escaping () -> ()) {
        let alertController = UIAlertController(title: "Sorry!",
                                                message: "Camera Access must be enabled from settings in order to use this feature",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default){ _ in
            completed()
        })
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: self.convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { _ in
                    completed()
                })
            }
        })
        present(alertController, animated: true)
    }
    
    func presentCameraRollSettings(completed: @escaping () -> ()) {
        let alertController = UIAlertController(
            title:
            "Sorry!",
            message:
            "Photo Library Access must be enabled from settings in order to use this feature",
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default) { _ in
            completed()
        })
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: self.convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { _ in
                    // Handle
                    completed()
                })
            }
        })
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
    
    fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
}

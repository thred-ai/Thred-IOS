//
//  NotificationVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-14.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import ColorCompatibility
import FirebaseFirestore


class UserNotification{
    
    var notifID: String!
    var uid: String!
    var notifType: String!
    var timestamp: Date!
    var timestampDiff: String!
    var username: String!
    var picID: String!
    var commentMessage: String?
    var commentID: String?
    var shouldShowDP: Bool!
    var templateColor: String!
    var product: Product!
    var userInfo: UserInfo!
    var deleted: Bool!
    
    init(notifID: String!, uid: String!, notifType: String!, timestamp: Date!, username: String!, picID: String!, shouldShowDP: Bool!, templateColor: String!, timestampDiff: String!, commentMessage: String?, commentID: String?, deleted: Bool!) {
        self.notifID = notifID
        self.uid = uid
        self.notifType = notifType
        self.timestamp = timestamp
        self.username = username
        self.picID = picID
        self.shouldShowDP = shouldShowDP
        self.templateColor = templateColor
        self.timestampDiff = timestampDiff
        self.commentMessage = commentMessage
        self.commentID = commentID
        self.deleted = deleted
    }
    
    convenience init(){
        self.init(notifID: nil, uid: nil, notifType: nil, timestamp: nil, username: nil, picID: nil, shouldShowDP: nil, templateColor: nil, timestampDiff: nil, commentMessage: nil, commentID: nil, deleted: nil)
    }
}

class NotificationVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var notifications = [UserNotification]()
    var downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return notifications.count
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.tabBarItem.badgeValue = nil
        self.navigationController?.tabBarItem.badgeColor = nil
        UIApplication.shared.applicationIconBadgeNumber = 0 // For Clear Badge Counts
    }
    
    var isLoading = false
    
    override func viewWillAppear(_ animated: Bool) {
        showCenterBtn()
        selectedComment = nil
        
        if self.navigationController?.tabBarItem.badgeColor != nil{
            if !isLoading{
                isLoading = true
                getNotifications(){
                    self.notifications.removeAll()
                    self.tableView.reloadData()
                    self.isLoading = false
                }
            }
        }
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else{return}
        tableView.deselectRow(at: selectedIndexPath, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath) as? NotificationCell
        let notif = notifications[indexPath.row]
        guard let uid = userInfo.uid else{return cell!}
        cell?.vc = self
        if let attr = cell?.notifLbl.attributedText.mutableCopy() as? NSMutableAttributedString{
            attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
            attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: cell?.notifLbl.font?.pointSize ?? 15)!], range: NSMakeRange(0, attr.length))
            cell?.notifLbl.attributedText = attr
        }
        cell?.notifLbl.text = nil
        cell?.notifPic.image = nil
        cell?.notifPic.backgroundColor = UIColor.clear
        cell?.notifPic.clipsToBounds = true
        cell?.timestampLbl.text = nil
        cell?.removedNotifView.isHidden = true
        cell?.isUserInteractionEnabled = false

        guard !notif.deleted else{
            cell?.removedNotifView.isHidden = false
            return cell!
        }
        isMentionBreak:
        if notif.username == nil{
            
            downloadUserInfo(uid: notif.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: !notif.shouldShowDP, downloader: downloader, userInfoToUse: nil, queryOnUsername: false, completed: {userUID, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postCount, followerCount, followingCount in
                
                if username == nil{
                    for sameNotif in self.notifications.filter({$0.uid == notif.uid}){
                        sameNotif.deleted = true
                        guard let index = self.notifications.firstIndex(where: {$0.notifID == sameNotif.notifID}) else{continue}
                        tableView.performBatchUpdates({
                            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }, completion: nil)
                    }
                    return
                }
                
                notif.username = username
                if let img = imgData{
                    cache.storeImageData(toDisk: img.jpegData(compressionQuality: 1.0), forKey: dpUID)
                    notif.picID = dpUID
                    cell?.notifPic.image = img
                    notif.userInfo.dp = img
                    notif.userInfo.username = username
                    notif.userInfo.fullName = fullName
                    notif.userInfo.dpID = dpUID
                    notif.userInfo.uid = notif.uid
                    notif.userInfo.bio = bio
                    notif.userInfo.postCount = postCount
                    notif.userInfo.followerCount = followerCount
                    notif.userInfo.followingCount = followingCount
                    notif.userInfo.userFollowing = userFollowing
                    notif.userInfo.notifID = notifID
                    notif.userInfo.usersBlocking = usersBlocking
                }
                else{
                    if notif.notifType != "Mention"{
                        if notif.product == nil{
                            notif.product = Product()
                        }
                        notif.product.username = userInfo.username
                        notif.product.fullName = userInfo.fullName
                        notif.product.userImageID = userInfo.dpID
                        notif.product.uid = uid
                    }
                }
                cell?.isUserInteractionEnabled = true
                self.setUsername(username: username, notif: notif, cell: cell)
            })
        }
        else{
            cell?.isUserInteractionEnabled = true
            self.setUsername(username: notif.username, notif: notif, cell: cell)
        }
        
        if !notif.shouldShowDP{
            cell?.isDP = false
            if notif.product == nil{
                notif.product = Product()
            }
            if let color = notif.templateColor{
                cell?.notifPic.backgroundColor = UIColor(named: color)
                if let img = cache.imageFromCache(forKey: notif.picID){
                    cell?.notifPic.image = img
                }
            }
            else{
                getPostBackgroundInfo(uid: uid, postID: notif.picID, completed: { product in
                    if product == nil{
                        for sameNotif in self.notifications.filter({$0.picID == notif.picID}){
                            sameNotif.deleted = true
                            guard let index = self.notifications.firstIndex(where: {$0.notifID == sameNotif.notifID}) else{continue}
                            tableView.performBatchUpdates({
                                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }, completion: nil)
                        }
                    }
                    else{
                        notif.product = product
                        guard let templateColor = product?.templateColor else{return}
                        notif.templateColor = templateColor
                        cell?.notifPic.backgroundColor = UIColor(named: templateColor)
                        if let img = cache.imageFromCache(forKey: notif.picID){
                            cell?.notifPic.image = img
                        }
                        else{
                            tableView.downloadProductImage(pictureProduct: nil, followingUID: uid, picID: notif.picID, index: 0, downloader: self.downloader, feedVC: nil, friendVC: nil, userVC: nil, fullVC: nil, type: nil, product: nil, completed: { img, imgID in
                                cache.storeImageData(toDisk: img?.pngData(), forKey: imgID)
                                notif.picID = imgID
                                cell?.notifPic.image = img
                            })
                        }
                    }
                })
            }
        }
        else{
            cell?.isDP = true
            if notif.userInfo == nil{
                notif.userInfo = UserInfo()
            }
            if let img = cache.imageFromCache(forKey: notif.picID){
                cell?.notifPic.image = img
                notif.userInfo.dp = img
            }
        }
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        return indexPath
    }
    
    var selectedObject: Any!
    var selectedComment: Comment!
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let notif = notifications[indexPath.row]
        if notif.shouldShowDP{
            selectedObject = notif.userInfo
            self.performSegue(withIdentifier: "toFriend", sender: nil)
        }
        else{
            selectedObject = notif.product
            
            if notif.notifType == "Mention" || notif.notifType == "Comment"{
                selectedComment = Comment(timestamp: notif.timestamp, message: notif.commentMessage, commentID: notif.commentID, userInfo: UserInfo(uid: notif.uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: nil, postCount: nil, followingCount: nil, usersBlocking: []))
            }
            self.performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    func setUsername(username: String?, notif: UserNotification, cell: NotificationCell?){
        
        guard !notif.deleted else{return}
        
        let spacing = "                         "
        if notif.notifType == "Follow"{
            cell?.notifLbl.text = "\(notif.username ?? spacing) started following you"
            cell?.notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Like"{
            cell?.notifLbl.text = "\(notif.username ?? spacing) liked your post"
            cell?.notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Buy"{
            cell?.notifLbl.text = "\(notif.username ?? spacing) purchased your post"
            cell?.notifLbl.textColor = UIColor(named: "ActiveColor")
        }
        else if notif.notifType == "Comment"{
            cell?.notifLbl.text = "\(notif.username ?? spacing) commented on your post: \(notif.commentMessage ?? "This comment cannot be displayed")"
            cell?.notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Mention"{
            cell?.notifLbl.text = "\(notif.username ?? spacing) mentioned you in a comment: \(notif.commentMessage ?? "This comment cannot be displayed")"
            cell?.notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        guard let cell = cell else{return}
        cell.notifLbl.addLinks(isNotification: true)
        tableView.checkNotifTimes(notif: notif, timestampLbl: cell.timestampLbl)
        
            UIView.setAnimationsEnabled(false)
            self.tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height > scrollView.visibleSize.height{
            if scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height){
                scrollView.contentOffset.y = scrollView.contentSize.height - scrollView.frame.size.height
            }
        }
    }
  
    
    
    
    
    func getPostBackgroundInfo(uid: String, postID: String, completed: @escaping (Product?) -> ()){
        Firestore.firestore().collectionGroup("Products").whereField("Product_ID", isEqualTo: postID).getDocuments(completion: { snaps, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                guard let snap = snaps?.documents.first else{
                    completed(nil)
                    return}
                let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                guard let uid = snap["UID"] as? String else{
                    return}
                let description = snap["Description"] as? String
                let name = snap["Name"] as? String
                let blurred = snap["Blurred"] as? Bool
                let templateColor = snap["Template_Color"] as? String
                let likes = snap["Likes"] as? Int
                guard let priceCents = (snap["Price_Cents"] as? Double) else{return}
                let comments = ((snap["Comments"]) as? Int) ?? 0

                completed(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: 0, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments))
                return
            }
        })
    }
    

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: "NotifCell")
        tableView.register(UINib(nibName: "SalesCell", bundle: nil), forCellReuseIdentifier: "SalesCell")
        let refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refresher)
        
        tableView.adjustForCenterBtn(footerColor: ColorCompatibility.systemBackground, offset: nil, vc: self)
        
        if !isLoading{
            isLoading = true
            getNotifications(){
                if self.notifications.isEmpty{
                    self.isLoading = false
                    self.tableView.reloadData()
                }
            }
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {

    }
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
                
        if !isLoading{
            isLoading = true
            isInitialPull = true
            sender.animateRefresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.getNotifications {
                    self.isLoading = false
                    self.notifications.removeAll()
                    self.tableView.reloadData()
                    sender.endRefreshing()
                }
            }
        }
    }
    
    var isInitialPull: Bool = true
    
    func getNotifications(completed: @escaping () -> ()){
        
        guard let uid = userInfo.uid else{return}
        refreshLists(userUID: uid){
            let query = Firestore.firestore().collection("Users/\(uid)/Notifications").order(by: "Timestamp", descending: true).limit(to: 20)
            query.getDocuments(completion: { snaps, error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    completed()
                }else{
                    if let docs = snaps?.documents, !docs.isEmpty{
                        completed()
                        for doc in docs{
                            guard let uid = doc["UID"] as? String else{
                                
                                continue}
                            if userInfo.usersBlocking.contains(uid){
                                continue
                            }
                            let timestamp = (doc["Timestamp"] as? Timestamp)?.dateValue()
                            
                            let type = doc["Type"] as? String
                            let picID = doc["Product_ID"] as? String
                            let commentMessage = doc["Comment_Message"] as? String
                            let commentID = doc["Comment_ID"] as? String

                            self.notifications.append(UserNotification(notifID: doc.documentID, uid: uid, notifType: type, timestamp: timestamp, username: nil, picID: picID, shouldShowDP: type == "Follow", templateColor: nil, timestampDiff: nil, commentMessage: commentMessage, commentID: commentID, deleted: false))
                            self.tableView.performBatchUpdates({
                                self.tableView.insertRows(at: [IndexPath(item: self.notifications.count - 1, section: 0)], with: .none)
                            }, completion: { finished in
                                if finished{
                                    if doc == docs.last{
                                        self.isInitialPull = false
                                    }
                                }
                            })
                        }
                    }
                    else{
                        completed()
                    }
                }
            })
        }
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 200
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let productVC = segue.destination as? FullProductVC{
            guard let product = selectedObject as? Product else{return}
            productVC.fullProduct = product
            productVC.selectedComment = selectedComment
        }
        if let userVC = segue.destination as? FriendVC{
            guard let user = selectedObject as? UserInfo else{return}
            userVC.friendInfo = user
        }
    }
    

}

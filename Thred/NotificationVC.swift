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


class UserNotification: Codable{
    
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
            downloadNotifs {
                
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
        cell?.vc = nil
        cell?.vc = self
        
        if let attr = cell?.notifLbl.attributedText.mutableCopy() as? NSMutableAttributedString{
            attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
            attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: cell?.notifLbl.font?.pointSize ?? 15)!], range: NSMakeRange(0, attr.length))
            cell?.notifLbl.attributedText = attr
        }
        cell?.notifLbl.text = nil
        cell?.notifPic.image = nil
        cell?.notifPic.backgroundColor = ColorCompatibility.secondarySystemBackground
        cell?.notifPic.clipsToBounds = true
        cell?.timestampLbl.text = nil
        cell?.removedNotifView.isHidden = true
        cell?.isUserInteractionEnabled = false
        cell?.notif = notif
        self.tableView.checkNotifTimes(notif: notif, timestampLbl: cell?.timestampLbl)

        guard !notif.deleted else{
            cell?.removedNotifView.isHidden = false
            return cell!
        }
        
        isMentionBreak:
        if notif.username == nil{
            
            downloadUserInfo(uid: notif.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: { userUID, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postCount, followerCount, followingCount in
                
                if username == nil{
                    for sameNotif in self.notifications.filter({$0.uid == notif.uid}){
                        sameNotif.deleted = true
                        guard let index = self.notifications.firstIndex(where: {$0.notifID == sameNotif.notifID}) else{continue}
                        DispatchQueue.main.async {
                            tableView.performBatchUpdates({
                                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }, completion: nil)
                        }
                    }
                    return
                }
                
                if notif.userInfo == nil{
                    notif.userInfo = UserInfo()
                }
                notif.username = username
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
                notif.userInfo.dp = imgData

                if let img = imgData, notif.shouldShowDP{
                    DispatchQueue(label: "cache").async {
                        cache.storeImageData(toDisk: img, forKey: dpUID)
                    }
                    cell?.notifPic.image = UIImage(data: img)
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
                cell?.notif = notif
            })
        }
        else{
            cell?.isUserInteractionEnabled = true
            cell?.notif = notif
        }
        
        if !notif.shouldShowDP{
            cell?.isDP = false
            if notif.product == nil{
                notif.product = Product()
            }
            if let color = notif.templateColor{
                cell?.notifPic.backgroundColor = UIColor(named: color)
                DispatchQueue(label: "cache").async {
                    if let img = cache.imageFromCache(forKey: notif.picID){
                        DispatchQueue.main.async {
                            cell?.notifPic.image = img
                        }
                    }
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
                        DispatchQueue(label: "cache").async {
                            if let img = cache.imageFromCache(forKey: notif.picID){
                                DispatchQueue.main.async {
                                    cell?.notifPic.image = img
                                }
                            }
                            else{
                                guard let productUID = product?.uid else{return}
                                DispatchQueue.main.async {
                                    tableView.downloadProductImage(pictureProduct: nil, followingUID: productUID, picID: notif.picID, index: 0, feedVC: nil, friendVC: nil, userVC: nil, fullVC: nil, type: nil, product: nil, completed: { img, imgID in
                                        DispatchQueue(label: "cache").async {
                                            cache.storeImageData(toDisk: img?.pngData(), forKey: imgID)
                                        }
                                        notif.picID = imgID
                                        cell?.notifPic.image = img
                                    })
                                }
                            }
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
            DispatchQueue(label: "cache").async {
                if let img = cache.imageFromCache(forKey: notif.userInfo.dpID){
                    DispatchQueue.main.async {
                        cell?.notifPic.image = img
                        notif.userInfo.dp = img.jpegData(compressionQuality: 1.0)
                    }
                }
            }
        }
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        return indexPath
    }
    
    var selectedObject: Any!
    var selectedComment: Comment!
    
    
    @IBAction func toCart(_ sender: UIBarButtonItem) {
        navigationController?.segueToCart()
    }
    
    @IBAction func toSales(_ sender: UIBarButtonItem) {
        navigationController?.segueToSales()
        
        
 
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let notif = notifications[indexPath.row]
        if notif.shouldShowDP{
            selectedObject = notif.userInfo
            self.performSegue(withIdentifier: "toFriend", sender: nil)
        }
        else{
            selectedObject = notif.product
            
            if notif.notifType == "Mention" || notif.notifType == "Comment"{
                selectedComment = Comment(timestamp: notif.timestamp, message: notif.commentMessage, commentID: notif.commentID, userInfo: UserInfo(uid: notif.uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: []))
            }
            self.performSegue(withIdentifier: "toFull", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            deleteNotif(indexPath: indexPath)
        }
    }
    
    func deleteNotif(indexPath: IndexPath){
        
        guard let uid = userInfo.uid else{return}
        guard let notifID = notifications[indexPath.row].notifID else{return}
        notifications.removeAll(where: {$0.notifID == notifID})
        
        DispatchQueue.main.async {
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }, completion: { finished in
                if finished{
                    Firestore.firestore().collection("Users/\(uid)/Notifications").document(notifID).delete(completion: { error in
                        if let err = error{
                            print(err.localizedDescription)
                        }
                    })
                }
            })
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

                completed(Product(uid: uid, picID: snap.documentID, description: description, fullName: nil, username: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, index: 0, timestampDiff: nil, blurred: blurred, price: priceCents / 100, name: name, templateColor: templateColor, likes: likes, liked: userInfo.userLiked.contains(snap.documentID), designImage: nil, comments: comments, link: nil))
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
                self.isLoading = false
                self.tableView.reloadData()
            }
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {

    }
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl){
                
        guard checkInternetConnection() else{
            sender.endRefreshing()
            return
        }
        
        if !isLoading{
            isLoading = true
            sender.animateRefresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadNotifs {
                    sender.endRefreshing()
                }
            }
        }
    }
    
    func downloadNotifs(completed: @escaping () -> ()){
        if !isLoading{
            isLoading = true
        }
        self.getNotifications {
            self.isLoading = false
            self.tableView.reloadData()
            completed()
        }
    }
    
    
    func getNotifications(completed: @escaping () -> ()){
        
        guard let uid = userInfo.uid else{return}
        checkAuthStatus {
            self.refreshLists(userUID: uid){
                let query = Firestore.firestore().collection("Users/\(uid)/Notifications").order(by: "Timestamp", descending: true).limit(to: 30)
                query.getDocuments(completion: { snaps, error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        completed()
                    }else{
                        if let docs = snaps?.documents, !docs.isEmpty{
                            self.notifications.removeAll()
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

                                self.notifications.append(UserNotification(notifID: doc.documentID, uid: uid, notifType: type, timestamp: timestamp, username: nil, picID: picID, shouldShowDP: type == "Follow" || type == "Bio_Mention", templateColor: nil, timestampDiff: nil, commentMessage: commentMessage, commentID: commentID, deleted: false))
                            }
                            completed()
                        }
                        else{
                            completed()
                        }
                    }
                })
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 200
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    lazy var headerView: UIView? = {
        
        return loadNotifHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        
        return loadLoadingHeaderFromNib()
    }()
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if notifications.isEmpty{
            if isLoading{
                loadingView?.spinner.animate()
                return loadingView
            }
            else{
                return headerView
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if notifications.isEmpty{
            return 100
        }
        return 0
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

extension UINavigationController{
    
    func pushViewControllerFromLeft(viewController: UIViewController){
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        pushViewController(viewController, animated: false)
    }
    
    func popViewControllerFromRight(viewController: UIViewController){
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        popViewController(animated: false)
    }
}

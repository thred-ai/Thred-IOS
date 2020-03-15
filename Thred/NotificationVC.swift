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


class UserNotification{
    
    var notifID: String!
    var uid: String!
    var notifType: String!
    var timestamp: Date!
    var username: String!
    var picID: String!
    var shouldShowDP: Bool!
    var templateColor: String!
    
    init(notifID: String!, uid: String!, notifType: String!, timestamp: Date!, username: String!, picID: String!, shouldShowDP: Bool!, templateColor: String!) {
        self.notifID = notifID
        self.uid = uid
        self.notifType = notifType
        self.timestamp = timestamp
        self.username = username
        self.picID = picID
        self.shouldShowDP = shouldShowDP
        self.templateColor = templateColor
    }
    
    convenience init(){
        self.init(notifID: nil, uid: nil, notifType: nil, timestamp: nil, username: nil, picID: nil, shouldShowDP: nil, templateColor: nil)
    }
}

class NotificationVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var notifications = [UserNotification]()
    var downloader = SDWebImageDownloader.init(config: SDWebImageDownloaderConfig.default)

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            return 1
        }
        else{
            return notifications.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SalesCell", for: indexPath) as? SalesCell
            
            return cell!
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath) as? NotificationCell
            
            let notif = notifications[indexPath.row]
            
            cell?.notifLbl.text = nil
            cell?.notifPic.image = nil
            cell?.notifPic.backgroundColor = UIColor.clear
            cell?.notifPic.clipsToBounds = true

            if notif.username == nil{
                
                tableView.downloadUserInfo(uid: notif.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: !notif.shouldShowDP, downloader: self.downloader, userInfo: nil, completed: { _, username, dpUID, _, _, imgData, _ in
                    notif.username = username
                    if let img = imgData{
                        cache.storeImageData(toDisk: img.pngData(), forKey: dpUID)
                        notif.picID = dpUID
                        cell?.notifPic.image = img
                    }
                    self.setUsername(username: username, notif: notif, cell: cell)
                })
            }
            else{
                self.setUsername(username: notif.username, notif: notif, cell: cell)
            }
            
            if !notif.shouldShowDP{
                cell?.isDP = false
                if let color = notif.templateColor{
                    cell?.notifPic.backgroundColor = UIColor(named: color)
                    if let img = cache.imageFromCache(forKey: notif.picID){
                        cell?.notifPic.image = img
                    }
                }
                else{
                    getPostBackgroundInfo(uid: userInfo.uid, postID: notif.picID, completed: { color in
                        notif.templateColor = color
                        guard let templateColor = color else{return}
                        cell?.notifPic.backgroundColor = UIColor(named: templateColor)
                        if let img = cache.imageFromCache(forKey: notif.picID){
                            cell?.notifPic.image = img
                        }
                        else{
                            tableView.downloadProductImage(pictureProduct: nil, followingUID: userInfo.uid, picID: notif.picID, index: 0, downloader: self.downloader, feedVC: nil, friendVC: nil, userVC: nil, fullVC: nil, type: nil, product: nil, completed: { img, imgID in
                                cache.storeImageData(toDisk: img?.pngData(), forKey: imgID)
                                notif.picID = imgID
                                cell?.notifPic.image = img
                            })
                        }
                    })
                }
            }
            else{
                cell?.isDP = true
                if let img = cache.imageFromCache(forKey: notif.picID){
                    cell?.notifPic.image = img
                }
            }
            return cell!
        }
    }
    
    func setUsername(username: String?, notif: UserNotification, cell: NotificationCell?){
        if notif.notifType == "Follow"{
            cell?.notifLbl.text = "\(notif.username ?? "null") started following you"
            cell?.notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Like"{
            cell?.notifLbl.text = "\(notif.username ?? "null") liked your post"
            cell?.notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Buy"{
            cell?.notifLbl.text = "\(notif.username ?? "null") purchased your post"
            cell?.notifLbl.textColor = UIColor(named: "ActiveColor")
        }
        else if notif.notifType == "Comment"{
            cell?.notifLbl.text = "\(notif.username ?? "null") commented on your post"
            cell?.notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
    }
    
    func getPostBackgroundInfo(uid: String, postID: String, completed: @escaping (String?) -> ()){
        Firestore.firestore().collection("Users/\(uid)/Products").document(postID).getDocument(completion: { snap, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                let colorID = snap?["Template_Color"] as? String
                completed(colorID)
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

        getNotifications(fromInterval: nil){
            
        }
        // Do any additional setup after loading the view.
    }
    
    var listener: ListenerRegistration!
    
    func getNotifications(fromInterval: Date?, completed: @escaping () -> ()){
        var query: Query!
        
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users/\(userInfo.uid)/Notifications").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).order(by: "Timestamp", descending: true).limit(to: 20)
        }
        else{
            guard let interval = fromInterval else{ completed(); return}
            query = Firestore.firestore().collection("Users/\(userInfo.uid)/Notifications").whereField("Timestamp", isLessThan: Timestamp(date: interval)).order(by: "Timestamp", descending: true).limit(to: 20)
        }
        
        query.getDocuments(completion: { snaps, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }else{
                if let docs = snaps?.documents, !docs.isEmpty{
                    
                    for snap in docs{ // LOADED DOCUMENTS FROM \(snapDocuments)
                        let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                        let uid = snap["UID"] as? String
                        let type = snap["Type"] as? String
                        let picID = snap["Product_ID"] as? String
                        self.notifications.append(UserNotification(notifID: snap.documentID, uid: uid, notifType: type, timestamp: timestamp, username: nil, picID: picID, shouldShowDP: type == "Follow", templateColor: nil))
                        
                        self.tableView.performBatchUpdates({
                            self.tableView.insertRows(at: [IndexPath(item: self.notifications.count - 1, section: 1)], with: .none)
                        }, completion: { finished in
                            if finished{
                                if snap == snaps?.documents.last{
                                    completed()
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
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0{
            return 55
        }
        return 65
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0{
            return 55
        }
        return 65
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

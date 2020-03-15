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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath) as? NotificationCell
        
        let notif = notifications[indexPath.row]
        
        cell?.notifLbl.text = nil
        cell?.notifPic.image = nil
        
        if notif.username != nil{
            if notif.notifType == "Follow"{
                cell?.notifLbl.text = "\(notif.username ?? "null") started following you"
            }
            else if notif.notifType == "Like"{
                cell?.notifLbl.text = "\(notif.username ?? "null") liked your post"
            }
            else if notif.notifType == "Buy"{
                cell?.notifLbl.text = "\(notif.username ?? "null") purchased your post"
            }
            else if notif.notifType == "Comment"{
                cell?.notifLbl.text = "\(notif.username ?? "null") commented on your post"
            }
        }
        
        if let color = notif.templateColor{
            cell?.notifPic.backgroundColor = UIColor(named: color)
        }
        else{
            cell?.notifPic.backgroundColor = UIColor.clear
        }
        
        if let img = cache.imageFromCache(forKey: notif.picID){
            cell?.notifPic.clipsToBounds = true
            if !notif.shouldShowDP{
                
                cell?.notifPic.image = img
                cell?.notifPic.layer.cornerRadius = 0
                if notif.templateColor == nil{
                    getPostBackgroundInfo(uid: userInfo.uid, postID: notif.picID, completed: { color in
                        notif.templateColor = color
                        tableView.performBatchUpdates({
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }, completion: nil)
                    })
                }
                if notif.username == nil{
                    tableView.downloadUserInfo(uid: notif.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: true, downloader: self.downloader, userInfo: nil, completed: { _, username, dpUID, _, _, imgData, _ in
                        notif.username = username
                        cache.storeImage(toMemory: imgData, forKey: dpUID)
                        tableView.performBatchUpdates({
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }, completion: nil)
                    })
                }
            }
            else{
                cell?.notifPic.layer.cornerRadius = (cell?.notifPic.frame.height ?? 0) / 2
                cell?.notifPic.image = img
            }
        }
        else{
            tableView.downloadUserInfo(uid: notif.uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: !notif.shouldShowDP, downloader: downloader, userInfo: nil, completed: { _, username, dpUID, _, _, imgData, _ in
                
                notif.username = username

                if notif.shouldShowDP{
                    notif.picID = dpUID
                    cache.storeImage(toMemory: imgData, forKey: dpUID)
                    tableView.performBatchUpdates({
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }, completion: nil)
                }
                else{
                    self.getPostBackgroundInfo(uid: userInfo.uid, postID: notif.picID, completed: { color in
                        notif.templateColor = color
                        tableView.downloadProductImage(pictureProduct: nil, followingUID: notif.uid, picID: notif.picID, index: 0, downloader: self.downloader, feedVC: nil, friendVC: nil, userVC: nil, fullVC: nil, type: nil, product: nil, completed: { img, imgID in
                            cache.storeImage(toMemory: img, forKey: imgID)
                            tableView.performBatchUpdates({
                                tableView.reloadRows(at: [indexPath], with: .none)
                            }, completion: nil)
                        })
                    })
                }
            })
        }
        return cell!
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
        
        getNotifications(fromInterval: nil){
            
        }
        // Do any additional setup after loading the view.
    }
    
    func getNotifications(fromInterval: Date?, completed: @escaping () -> ()){
        var query: Query!
        
        if fromInterval == nil{
            query = Firestore.firestore().collection("Users/\(userInfo.uid)/Notifications").whereField("Timestamp", isLessThanOrEqualTo: Timestamp(date: Date())).order(by: "Timestamp", descending: true).limit(to: 12)
        }
        else{
            guard let interval = fromInterval else{ completed(); return}
            query = Firestore.firestore().collection("Users/\(userInfo.uid)/Notifications").whereField("Timestamp", isLessThan: Timestamp(date: interval)).order(by: "Timestamp", descending: true).limit(to: 12)
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
                            self.tableView.insertRows(at: [IndexPath(item: self.notifications.count - 1, section: 0)], with: .none)
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
        return 65
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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

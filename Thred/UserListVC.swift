//
//  UserListVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

enum UserListType{
    case followers
    case following
}

class UserListVC: UITableViewController {

    var listType: UserListType!
    var listUsers: [UserInfo]! = [UserInfo]()
    var selectedUser: UserInfo!
    var user: UserInfo!
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "SearchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "search")
        isLoading = true
        tableView.adjustForCenterBtn(footerColor: nil, offset: 5, vc: self)

        getUsers(fromInterval: nil){
            self.isLoading = false
        }
        guard let listType = listType else{return}
        navigationItem.title = "\(listType)".capitalizingFirstLetter()
    }
    
    var lastDoc: DocumentSnapshot!
    
    func getUsers(fromInterval: DocumentSnapshot?, completed: @escaping () -> ()){
        var query: Query!
        
        guard let uid = user?.uid else{return}
        if listType == .followers{
            if fromInterval == nil{
                query = Firestore.firestore().collection("Users/\(uid)/Followers")
            }
            else if let lastDoc = fromInterval{
                query = Firestore.firestore().collection("Users/\(uid)/Followers").start(afterDocument: lastDoc)
            }
        }
        else if listType == .following{
            if fromInterval == nil{
                query = Firestore.firestore().collection("Users/\(uid)/Following")
            }
            else if let lastDoc = fromInterval{
                query = Firestore.firestore().collection("Users/\(uid)/Following").start(afterDocument: lastDoc)
            }
        }
        query?.limit(to: 20).getDocuments(completion: { snaps, error in
            guard let docs = snaps?.documents, !docs.isEmpty else{return}
            self.lastDoc = docs.last
            for doc in docs{
                let uid = doc.documentID
                Firestore.firestore().collection("Users").document(uid).getDocument(completion: { document, error in
                    if let err = error{
                        print(err.localizedDescription)
                    }
                    else{
                        if let document = document, document.exists{
                            let username = document["Username"] as? String
                            let fullname = document["Full_Name"] as? String
                            let bio = document["Bio"] as? String
                            let dpLink = document["ProfilePicID"] as? String
                            let userFollowing = document["Following_List"] as? [String]
                            let followerCount = document["Followers_Count"] as? Int
                            let followingCount = document["Following_Count"] as? Int
                            let postCount = document["Posts_Count"] as? Int
                            let usersBlocking = document["Users_Blocking"] as? [String]
                            let user = UserInfo(uid: uid, dp: nil, dpID: dpLink, username: username, fullName: fullname, bio: bio, notifID: nil, userFollowing: userFollowing ?? [], userLiked: [], followerCount: followerCount ?? 0, postCount: postCount ?? 0, followingCount: followingCount ?? 0, usersBlocking: usersBlocking ?? [], profileLink: nil)
                            self.listUsers.append(user)
                            self.tableView.performBatchUpdates({
                                self.tableView.insertRows(at: [IndexPath(row: self.listUsers.count - 1, section: 0)], with: .none)
                            }, completion: { finished in
                                if finished{
                                    if doc == docs.last{
                                        completed()
                                    }
                                }
                            })
                            if uid == userInfo.uid{
                                user.dp = userInfo.dp
                                user.dpID = userInfo.dpID
                                user.username = userInfo.username
                                user.fullName = userInfo.fullName
                                if let index = self.listUsers.firstIndex(where: {$0.uid == uid}){
                                    if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SearchUserTableViewCell{
                                        cell.usernameLbl.text = "@\(user.username ?? "null")"
                                        cell.fullnameLbl.text = user.fullName
                                        guard let imgData = userInfo.dp else{return}
                                        cell.userImageView.image = UIImage(data: imgData)
                                        cell.spinner.isHidden = true
                                    }
                                }
                                return
                            }
                            let ref = Storage.storage().reference()
                            ref.child("Users/" + uid + "/" + "profile_pic-" + (dpLink ?? "null") +
                                ".jpeg").downloadURL(completion: { url, error in
                                if error != nil{
                                    print(error?.localizedDescription ?? "")
                                }
                                else{
                                    downloader.requestImage(with: url, options: [.scaleDownLargeImages, .refreshCached], context: nil, progress: nil, completed: { (image, data, error, finished) in
                                        if error != nil{
                                            print(error?.localizedDescription ?? "")
                                            return
                                        }
                                        else{
                                            user.dp = data
                                            if let index = self.listUsers.firstIndex(where: {$0.uid == uid}){
                                                if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SearchUserTableViewCell{
                                                    
                                                    cell.usernameLbl.text = "@\(user.username ?? "null")"
                                                    cell.fullnameLbl.text = user.fullName
                                                    cell.userImageView.image = image
                                                    cell.spinner.isHidden = true
                                                }
                                            }
                                        }
                                    })
                                }
                            })
                        }
                        else{
                            userInfo.userFollowing.removeAll(where: {$0 == uid})
                            self.listUsers.removeAll(where: {$0.uid == uid})
                            self.tableView.reloadData()
                            self.removeFromLists(uidToRemove: uid)
                        }
                    }
                })
            }
        })
    }
    
    func removeFromLists(uidToRemove: String){
        
        guard let uid = user.uid else{return}
        let data = [
            "uid" : uid,
            "uidToRemove" : uidToRemove
        ]
        Functions.functions().httpsCallable("deletedUserListCleanUp").call(data, completion: { result, error in
            
        })
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) / 2{
            print("fromScroll")
            if !isLoading, canLoadMore{
                isLoading = true
                getUsers(fromInterval: lastDoc, completed: {
                    self.isLoading = false
                })
            }
        }
    }
    
    var canLoadMore = false
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 0 {
            canLoadMore = false
            // swipes from top to bottom of screen -> down
        } else {
            canLoadMore = true
            // swipes from bottom to top of screen -> up
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return listUsers.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as? SearchUserTableViewCell
        let user = listUsers[indexPath.row]
        cell?.usernameLbl.text = nil
        cell?.fullnameLbl.text = nil
        cell?.userImageView.image = nil
        cell?.spinner.isHidden = false
        cell?.usernameLbl.text = "@\(user.username ?? "null")"
        cell?.fullnameLbl.text = user.fullName
        if let imgData = user.dp{
            cell?.userImageView.image = UIImage(data: imgData)
        }
        if cell?.userImageView.image == nil{
            cell?.spinner.animate()
        }
        else{
            cell?.spinner.isHidden = true
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedUser = listUsers[indexPath.row]
        self.performSegue(withIdentifier: "toFriend", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if listUsers[indexPath.row].uid == userInfo.uid{
            return nil
        }
        return indexPath
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
        if let vc = segue.destination as? FriendVC{
            vc.friendInfo = selectedUser
        }
    }
    
}

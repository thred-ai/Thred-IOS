//
//  AllChatsVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-08-22.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import PopupDialog

class AllChatsVC: UITableViewController, UISearchBarDelegate {

    var chats = [GroupChat]()
    @IBOutlet weak var newChatBtn: UIButton!
    
    @IBAction func newChat(_ sender: UIButton) {
        searchBarTextDidBeginEditing(searchBar)
        searchUsers(getFollowingOnly: true, searchText: "")
    }
    
    lazy var searchBar: UISearchBar = {
        
        let search = UISearchBar()
        search.autocapitalizationType = .none
        search.returnKeyType = .search
        search.searchBarStyle = .default
        search.keyboardType = .alphabet
        search.tintColor = UIColor(named: "LoadingColor")
        search.placeholder = "Search users"
        search.showsCancelButton = false
        
        search.searchTextField.font = UIFont(name: "NexaW01-Heavy", size: 14)
        search.searchTextField.adjustsFontSizeToFitWidth = true
        search.isTranslucent = false
        search.searchTextField.minimumFontSize = 12
        if #available(iOS 13.0, *) {
            let attributes:[NSAttributedString.Key:Any] = [
                NSAttributedString.Key.foregroundColor : UIColor.label,
                NSAttributedString.Key.backgroundColor : UIColor.clear,
                NSAttributedString.Key.font : UIFont(name: "NexaW01-Heavy", size: 16)!
            ]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            
        } else {
            let attributes:[NSAttributedString.Key:Any] = [
                NSAttributedString.Key.foregroundColor : UIColor.black,
                NSAttributedString.Key.backgroundColor : UIColor.clear,
                NSAttributedString.Key.font : UIFont(name: "NexaW01-Heavy", size: 16)!
            ]
            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes(attributes, for: .normal)
            // Fallback on earlier versions
        }
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor(named: "ProfileMask")
        
        return search
    }()
    
    var searchUsersTable: UITableView!
           
    lazy var searchView: UIView = {
        
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(1)

        
        searchUsersTable = UITableView(frame: CGRect(x: 0, y: 5, width: view.frame.width, height: view.frame.height - 5))
        searchUsersTable.separatorStyle = .none
        searchUsersTable.register(UINib(nibName: "SearchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "search")
        searchUsersTable.delegate = self
        searchUsersTable.dataSource = self
        searchUsersTable.backgroundColor = .clear

        view.addSubview(searchUsersTable)
        
        return view
    }()
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == searchUsersTable{
            return 55
        }
        return UITableView.automaticDimension
    }
    
    var searchedUsers = [UserInfo]()

    func searchUsers(getFollowingOnly: Bool, searchText: String){
        
        if searchText == "", !getFollowingOnly{
            searchedUsers.removeAll()
            searchUsersTable.reloadData()
            //self.getFollowers()
        }
        else{
            //searchBar.isLoading = true
            var query = Firestore.firestore().collection("Users").whereField("Username", isGreaterThanOrEqualTo: searchText).whereField("Username", isLessThanOrEqualTo: searchText + "\u{f8ff}").limit(to: 8)
            if getFollowingOnly{
                guard let uid = pUserInfo.uid else{return}

                query = Firestore.firestore().collection("Users/\(uid)/Following").limit(to: 10)
            }
            
            query.getDocuments(completion: { query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{

                                let uid = document.documentID

                                if pUserInfo.usersBlocking.contains(uid){
                                    if document == documents.first{
                                        self.searchedUsers.removeAll()
                                    }
                                    continue
                                }
                                else{
                                    if document == documents.first{
                                        self.searchedUsers.removeAll()
                                    }
                                }
                                
                                self.checkToDownloadUserInfo(onlyFollowing: getFollowingOnly, document: document, completed: { user in
                                    if uid == pUserInfo.uid{
                                        user.dp = pUserInfo.dp
                                        user.dpID = pUserInfo.dpID
                                        self.searchedUsers.append(user)
                                        self.searchUsersTable.reloadData()
                                        return
                                    }
                                    
                                    if !self.searchedUsers.contains(where: {$0.uid == document.documentID}){
                                        self.searchedUsers.append(user)
                                    }
                                    self.searchUsersTable.reloadData()
                                    let ref = Storage.storage().reference()
                                    ref.child("Users/" + uid + "/" + "profile_pic-" + (user.dpID ?? "null") +
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
                                                    if let index = self.searchedUsers.firstIndex(where: {$0.uid == uid}){
                                                        self.searchUsersTable.performBatchUpdates({
                                                            self.searchUsersTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                                        }, completion: nil)
                                                    }
                                                }
                                            })
                                        }
                                    })
                                })
                            }
                        }
                        else{
                            self.searchUsersTable.reloadData() //No Results
                        }
                    }
                }
            })
        }
    }
    
    func checkToDownloadUserInfo(onlyFollowing: Bool, document: QueryDocumentSnapshot, completed: @escaping (UserInfo) -> ()){
        if onlyFollowing{
            let uid = document["UID"] as? String
            downloadUserInfo(uid: uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: true, userInfoToUse: nil, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postNotifs, postCount, followersCount, followingCount, verified in
                
                completed(UserInfo(uid: uid, dp: imgData, dpID: dpUID, username: username, fullName: fullName, bio: bio, notifID: notifID, userFollowing: [], userLiked: [], followerCount: followersCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking, profileLink: nil, verified: verified))
            })
        }
        else{
            let uid = document.documentID
            let username = document["Username"] as? String
            let fullname = document["Full_Name"] as? String
            let bio = document["Bio"] as? String
            let dpLink = document["ProfilePicID"] as? String
            let userFollowing = document["Following_List"] as? [String]
            let followerCount = document["Followers_Count"] as? Int
            let followingCount = document["Following_Count"] as? Int
            let postCount = document["Posts_Count"] as? Int
            let usersBlocking = document["Users_Blocking"] as? [String]
            let verified = document["Verified"] as? Bool ?? false
            
            completed(UserInfo(uid: uid, dp: nil, dpID: dpLink, username: username, fullName: fullname, bio: bio, notifID: nil, userFollowing: userFollowing ?? [], userLiked: [], followerCount: followerCount ?? 0, postCount: postCount ?? 0, followingCount: followingCount ?? 0, usersBlocking: usersBlocking ?? [], profileLink: nil, verified: verified))
        }
    }
    
    var refresher: BouncingTitleRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        navigationItem.titleView = searchBar

        refresher = BouncingTitleRefreshControl(title: "thred")
        refresher.addTarget(self, action: #selector(self.refresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refresher)
        getChats(startAfter: nil){
            self.isLoading = false
            if self.chats.isEmpty{
                self.tableView.reloadData()
                self.checkToRemoveBadge(chat: nil)
            }
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if tableView == self.tableView && chats.indices.contains(indexPath.row){
            return true
        }
        return false
    }
    
    func muteOrUnMute(chat: GroupChat) -> Bool{
        
        var data = [String : Any]()
        
        if chat.didMute{
            data["Muted"] = FieldValue.arrayRemove([pUserInfo.uid ?? ""])
        }
        else{
            data["Muted"] = FieldValue.arrayUnion([pUserInfo.uid ?? ""])
        }
        Firestore.firestore().collection("Chats").document(chat.chatID).updateData(data, completion: { error in
            if let err = error{
                print(err.localizedDescription)
            }
        })
        return !chat.didMute
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard tableView == self.tableView else{return nil}
        var actions = [UIContextualAction]()
        
        if self.chats.indices.contains(indexPath.row){

            let chat = self.chats[indexPath.row]
            let leave = UIContextualAction(style: .normal, title: nil,
              handler: { (action, view, completionHandler) in
                if self.chats.indices.contains(indexPath.row){
                    let didMute = self.muteOrUnMute(chat: chat)
                    
                    if didMute{
                        action.image = UIImage(systemName: "bell.slash")
                    }
                    else{
                        action.image = UIImage(systemName: "bell")
                    }
                    if let same = self.chats.firstIndex(where: {$0.chatID == chat.chatID}){
                        self.chats[same].didMute = didMute
                        
                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: [IndexPath(row: same, section: 0)], with: .fade)
                        }, completion: nil)
                    }
                    completionHandler(true)
                }
            })

            if chat.didMute ?? false{
                leave.image = UIImage(systemName: "bell")
            }
            else{
                leave.image = UIImage(systemName: "bell.slash")
            }
            
            leave.backgroundColor = UIColor.systemGray
            actions.append(leave)
            
            if self.chats.indices.contains(indexPath.row){
                let delete = UIContextualAction(style: .destructive, title: nil,
                  handler: { (action, view, completionHandler) in
                    self.showDeleteChatMessage(chat: chat){
                        self.chats.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            self.tableView.performBatchUpdates({
                                self.tableView.deleteRows(at: [indexPath], with: .fade)
                            }, completion: { finished in
                                self.tableView.reloadData()
                            })
                        }
                    }
                    completionHandler(true)
                })
                
                delete.image = UIImage(systemName: "xmark.square")
                delete.backgroundColor = UIColor.red
                actions.append(delete)
            }
        }
        let configuration = UISwipeActionsConfiguration(actions: actions)
        return configuration
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == searchUsersTable{
            return 40
        }
        else if tableView == self.tableView{
            if chats.isEmpty{
                return 300
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == searchUsersTable{
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 40))
            let label = UILabel(frame: CGRect(x: 10, y: 0, width: view.frame.width - 20, height: view.frame.height))
            view.addSubview(label)
            label.font = UIFont(name: "NexaW01-Heavy", size: 16)
            label.textColor = .label
            label.text = "Suggested"
            label.textAlignment = .left
            return view
        }
        else if tableView == self.tableView{
            if chats.isEmpty{
                
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
        return nil
    }
    
    lazy var headerView: UIView? = {
        
        return loadChatPostHeaderFromNib()
    }()
    
    lazy var loadingView: LoadingView? = {
        return loadLoadingHeaderFromNib()
    }()
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == searchUsersTable{
            if searchUsersTable.numberOfRows(inSection: 0) != 0{
                searchBar.resignFirstResponder()
            }
        }
        else if scrollView == tableView{
            
            if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) / 2{
                if !isLoading, canLoadMore{
                    isLoading = true
                    print("fromScroll")
                    getChats(startAfter: lastDoc){
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
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
    
    var isLoading = true
    var canLoadMore = false
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
        
        self.navigationItem.setHidesBackButton(false, animated: false)

        self.searchedUsers.removeAll()
        searchUsersTable.reloadData()
        searchBar.text?.removeAll()
        UIView.animate(withDuration: 0.1, animations: {
            self.searchView.alpha = 0.0
        }, completion: {(finished : Bool) in
            self.searchView.isHidden = true
            self.tableView.isScrollEnabled = true
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        
        if self.isMovingFromParent{
            for listener in listeners ?? []{
                listener?.remove()
            }
        }
        //listener.remove()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideCenterBtn()
        
        
    }

    var listeners: [ListenerRegistration?]? = [ListenerRegistration?]()
    var lastDoc: DocumentSnapshot!
    
    func getChats(startAfter: DocumentSnapshot!, completed: @escaping () -> ()){
       //remove
        var query: Query!
        

        if let doc = startAfter{
            query = Firestore.firestore().collection("Chats").whereField("Members", arrayContains: pUserInfo.uid ?? "").order(by: "Timestamp", descending: true).start(afterDocument: doc).limit(to: 20)
        }
        else{
            query = Firestore.firestore().collection("Chats").whereField("Members", arrayContains: pUserInfo.uid ?? "").order(by: "Timestamp", descending: true).limit(to: 20)
        }
        let listener = query?.addSnapshotListener(includeMetadataChanges: false, listener: { snapshot, error in
            
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                
                guard let docs = snapshot?.documentChanges else{
                    return
                }

                if docs.isEmpty, self.refresher?.isRefreshing ?? false{
                    self.chats.removeAll()
                    completed()
                    return
                }
                
                var loadedCounter = 0
                var removedDocs = 0
                
                if docs.isEmpty{
                    completed()
                    
                }
                
                for docChange in docs{
                    
                    if docChange == docs.last{
                        self.lastDoc = docChange.document
                    }
                    let snap = docChange.document
                    
                    if self.chats.contains(where: {$0.chatID == snap.documentID}), docChange.type == .added{
                        removedDocs += 1
                        if removedDocs == docs.count{
                            completed()
                            return
                        }
                        else{
                            continue
                        }
                    }
                    
                    if !self.chats.isEmpty, self.refresher?.isRefreshing ?? false, docChange == docs.first{
                        self.chats.removeAll()
                    }
                    
                    let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                    let activeTime = (snap["Active"] as? Timestamp)?.dateValue()
                    let uids = snap["Original_Members"] as? [String] ?? []
                    let muteList = snap["Muted"] as? [String] ?? []

                    
                    let uid = uids.filter({$0 != pUserInfo.uid}).first ?? pUserInfo.uid

                    self.downloadUserInfo(uid: uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postNotifs, postCount, followersCount, followingCount, verified in
                        
                        let userInfo = UserInfo(uid: uid, dp: imgData, dpID: dpUID, username: username, fullName: fullName, bio: bio, notifID: notifID, userFollowing: userFollowing, userLiked: [], followerCount: followersCount, postCount: postCount, followingCount: followingCount, usersBlocking: usersBlocking, profileLink: nil, verified: verified)
                        
                        let ref = Firestore.firestore().collection("Chats").document(snap.documentID).collection("Messages")
                        
                        ref.order(by: "Timestamp", descending: true).limit(to: 1).getDocuments(completion: { snaps, error in
                            
                            if let err = error{
                                print(err.localizedDescription)
                                completed()
                            }
                            else{
                                if let doc = snaps?.documents.first{
                                    let msg = doc["Message"] as? String
                                    let removed = doc["Deleted"] as? Bool ?? false
                                    let didSee = (doc["readBy"] as? [String])?.contains(pUserInfo.uid ?? "") ?? false
                                    let uid = doc["UID"] as? String

                                    let gc = GroupChat(uids: uids, chatID: snap.documentID, userImageIDs: [], timestamp: timestamp, isActive: true, index: 0, activeTime: activeTime, activeTimeDiff: nil, timestampDiff: nil, lastText: nil, chatName: nil, displayUserInfo: userInfo, didMute: muteList.contains(pUserInfo.uid ?? ""))
                                    gc.chatName = userInfo.fullName
                                    gc.didRead = didSee
                                    
                                    if removed{
                                        gc.lastText = "unsent a message"
                                    }
                                    else{
                                        let isPic = doc["isPic"] as? Bool
                                        if isPic ?? false{
                                            gc.lastText = "sent a photo"
                                            if uid == pUserInfo.uid{
                                                gc.lastText = "You \(gc.lastText ?? "")"
                                            }
                                        }
                                        else{
                                            gc.lastText = msg
                                            if uid == pUserInfo.uid{
                                                gc.lastText = "You: \(gc.lastText ?? "")"
                                            }
                                        }
                                    }
                                    loadedCounter += 1
                                    
                                    if docChange.type == .added{
                                        
                                        self.chats.sort(by: {$0.timestamp > $1.timestamp})
                                        
                                        if !self.chats.contains(where: {$0.chatID == snap.documentID}){
                                            self.chats.append(gc)
                                        }
                                        
                                        
                                        print("Loaded: \(loadedCounter)")
                                        print("All: \(docs.count)")
                                        print("Removed: \(removedDocs)")

                                        if loadedCounter == docs.count - removedDocs{
                                            print(loadedCounter)
                                            completed()
                                            self.chats.sort(by: {$0.timestamp > $1.timestamp})
                                            DispatchQueue.main.async {
                                                self.tableView.reloadData()
                                            }
                                        }
                                    }
                                    else if docChange.type == .modified{
                                        
                                        if let chatIndex = self.chats.firstIndex(where: {$0.chatID == snap.documentID}){
                                            let chat = self.chats[chatIndex]
                                            
                                            chat.activeTime = activeTime
                                            chat.timestamp = timestamp
                                            chat.uids = uids
                                            chat.chatName = userInfo.fullName
                                            chat.displayUserInfo = userInfo
                                            chat.lastText = gc.lastText
                                            chat.didRead = gc.didRead
                                            
                                            if !(chat.didRead ?? false){
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            }
                                            
                                            self.chats.sort(by: {$0.timestamp > $1.timestamp})
                                            
                                            DispatchQueue.main.async {
                                                self.tableView.reloadData()
                                            }
                                            completed()
                                        }
                                    }
                                }
                                else{
                                    
                                    print(docs.count)
                                    
                                }
                            }
                        })
                    })
                }
            }
        })
        self.listeners?.append(listener)
    }

    
    override func viewDidLayoutSubviews() {
        if !view.subviews.contains(searchView){
            view.addSubview(searchView)
            view.bringSubviewToFront(searchView)
            searchView.isHidden = true
        }
        searchView.frame.origin.y = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            for path in self.tableView.indexPathsForSelectedRows ?? []{
                self.tableView.deselectRow(at: path, animated: false)
            }
        }
    }

    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchView.isHidden = false
        navigationItem.setHidesBackButton(true, animated: true)
        searchBar.setShowsCancelButton(true, animated: true)
        tableView.isScrollEnabled = false
        UIView.animate(withDuration: 0.1, animations: {
            self.searchView.alpha = 1.0
        }, completion: {(finished : Bool) in
            if finished{
            }
        })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        searchBar.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            self.searchBar.setShowsCancelButton(false, animated: false)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let lowerCaseSearchText = searchText.lowercased()
        searchBar.text = lowerCaseSearchText
        searchUsers(getFollowingOnly: false, searchText: lowerCaseSearchText)
    }

    var selectedChat: GroupChat!
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tableView{
            guard chats.indices.contains(indexPath.row) else{
                
                return}
            selectedChat = chats[indexPath.row]
            self.performSegue(withIdentifier: "toChat", sender: nil)
        }
        else{
            let user = searchedUsers[indexPath.row]
            guard let uid = pUserInfo.uid, let userUID = user.uid, uid != userUID else{return}
            checkForExistingChat(uid: uid, friendUserInfo: user, friendUID: userUID, completed: { gc in
                if let chat = gc{
                    self.selectedChat = chat
                }
                else{
                    let docID = Firestore.firestore().collection("Chats").document().documentID
                    let uids = [uid, userUID]
                    let chat = GroupChat(uids: uids, chatID: docID, userImageIDs: nil, timestamp: Date(), isActive: false, index: 0, activeTime: Date(), activeTimeDiff: nil, timestampDiff: nil, lastText: nil, chatName: user.fullName, displayUserInfo: user, didMute: false)
                    self.selectedChat = chat
                }
                self.searchBarCancelButtonClicked(self.searchBar)
                self.navigationItem.setHidesBackButton(false, animated: true)
                self.performSegue(withIdentifier: "toChat", sender: nil)
            })
        }
    }
    
    func checkForExistingChat(uid: String, friendUserInfo: UserInfo!, friendUID: String, completed: @escaping (GroupChat?) -> ()){
        
        if let chat = chats.first(where: {$0.uids.contains(uid) && $0.uids.contains(friendUID)}){
            completed(chat)
            return
        }
        
        queryExistingChats(uid: uid, friendUID: friendUID, friendUserInfo: friendUserInfo, completed: { chat in
            completed(chat)
        })
        
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if tableView == searchUsersTable{
            return searchedUsers.count
        }
        return chats.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == searchUsersTable{

            let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as? SearchUserTableViewCell
            guard searchedUsers.indices.contains(indexPath.row) else{return cell!}
            let user = self.searchedUsers[indexPath.row]
            cell?.userImageView.image = nil
            cell?.fullnameLbl.text = nil
            cell?.usernameLbl.text = nil
            cell?.fullnameLbl.attributedText = nil
            
            if let dp = user.dp{
                cell?.spinner.isHidden = true
                cell?.userImageView.image = UIImage(data: dp)
            }
            else{
                cell?.spinner.isHidden = false
                cell?.spinner.animate()
            }
            cell?.usernameLbl.text = "@" + (user.username ?? "null")
            cell?.fullnameLbl.text = user.fullName
            if user.verified{
                cell?.fullnameLbl.setVerified(name: user.fullName ?? "")
            }
            return cell!
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as? ChatCell
        guard chats.indices.contains(indexPath.row) else{return cell!}
        let chat = chats[indexPath.row]
        
        cell?.chatNameBtn.titleLabel?.attributedText = nil
        cell?.chatNameBtn.setAttributedTitle(nil, for: .normal)
        
        cell?.chatNameBtn.titleLabel?.text = chat.chatName
        cell?.chatNameBtn.setTitle(chat.chatName, for: .normal)
        if chat.displayUserInfo?.verified ?? false{
            cell?.chatNameBtn.setVerified(name: chat.chatName)
        }
        
        cell?.chatMsgLbl.text = chat.lastText
        
        cell?.speakerView.isHidden = !(chat.didMute ?? false)
        
        cell?.chatPicView.image = nil
        
        if chat.didRead ?? false{
            cell?.newIcon.isHidden = true
            cell?.chatMsgLbl.font = UIFont(name: "NexaW01-Regular", size: 14)
            cell?.chatMsgLbl.textColor = .tertiaryLabel
        }
        else{
            cell?.newIcon.isHidden = false
            cell?.chatMsgLbl.font = UIFont(name: "NexaW01-Heavy", size: 14)
            cell?.chatMsgLbl.textColor = .label
        }
        
        
        if let data = chat.displayUserInfo.dp, let image = UIImage(data: data){
            cell?.chatPicView.image = image
        }
        
            
        tableView.checkChatTimes(chat: chat, timestampLbl: cell?.tiimestampLbl)
        
        // Configure the cell...
        
        

        return cell!
    }
    
    
    
    @objc func refresh(_ sender: BouncingTitleRefreshControl?){
                
        guard checkInternetConnection() else{
            sender?.endRefreshing()
            return
        }
        isLoading = false

        if sender?.isRefreshing ?? false{
            isLoading = true
            sender?.animateRefresh()
            for listener in self.listeners ?? []{
                listener?.remove()
            }
            listeners?.removeAll()
            
            self.getChats(startAfter: nil, completed: {
                self.isLoading = false
                DispatchQueue.main.async {
                    sender?.endRefreshing()
                    if self.chats.isEmpty{
                        self.tableView.reloadData()
                        self.checkToRemoveBadge(chat: nil)
                    }
                }
            })
        }
        else{
            sender?.endRefreshing()
        }
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
        if let chatVC = segue.destination as? ChatVC{
            chatVC.chatInfo = selectedChat
        }
    }
    
    func checkToRemoveBadge(chat: GroupChat?){
        if let chat = chat{
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["Text-\(chat.chatID)"])
        }
        else{
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            appDelegate.getCurrentNotifs(onlyText: true, completed: { notifs in
                DispatchQueue.main.async {
                    if notifs.count == 0{
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                    appDelegate.checkNotifInfo(force: false)
                }
            })
        }
    }

}

extension GroupChat{
    func delete(){
        
        let data = [
            "Members" : FieldValue.arrayRemove([pUserInfo.uid ?? ""])
        ]
        
        Firestore.firestore().collection("Chats").document(chatID).updateData(data, completion: { error in
            if let err = error{
                print(err.localizedDescription)
            }
        })
    }
    
}

extension AllChatsVC{
    func showDeleteChatMessage(chat: GroupChat!, completed: @escaping () -> ()){
        
        let title = "Delete Conversation?"
        let message = "Deleting removes the conversation from your inbox, but no one else's inbox"
        
        let deleteBtn = DefaultButton(title: "Delete", dismissOnTap: true) {
            self.checkToRemoveBadge(chat: chat)
            chat.delete()
            completed()
        }
        let cancelBtn = DefaultButton(title: "Cancel", dismissOnTap: true) {}
        
        showPopUp(title: title, message: message, image: nil, buttons: [deleteBtn, cancelBtn], titleColor: .label, blurBack: true, transitionStyle: PopupDialogTransitionStyle.zoomIn, dismissOnlyBtns: false)
    }
}

extension Array where Element == String{
    func sortedAlphabet() -> [String]{
        return sorted(by: <)
    }
}

extension UIViewController{
    func queryExistingChats(uid: String, friendUID: String, friendUserInfo: UserInfo, completed: @escaping (GroupChat?) -> ()){
        Firestore.firestore().collection("Chats").whereField("Original_Members", isEqualTo: [uid, friendUID].sortedAlphabet()).getDocuments(completion: { snaps, error in
            if let err = error{
                print(err.localizedDescription)
                completed(nil)
            }
            else{
                                
                guard let docs = snaps?.documents, !docs.isEmpty
                    else{
                        
                        completed(nil);return}
                
                let doc = docs.first!
                
                let timestamp = (doc["Timestamp"] as? Timestamp)?.dateValue()
                let activeTime = (doc["Active"] as? Timestamp)?.dateValue()
                let uids = doc["Original_Members"] as? [String] ?? []
                let muteList = doc["Muted"] as? [String] ?? []

                let gc = GroupChat(uids: uids, chatID: doc.documentID, userImageIDs: nil, timestamp: timestamp, isActive: true, index: nil, activeTime: activeTime, activeTimeDiff: nil, timestampDiff: nil, lastText: nil, chatName: friendUserInfo.fullName ?? "", displayUserInfo: friendUserInfo, didMute: muteList.contains(pUserInfo.uid ?? ""))
                completed(gc)
            }
        })
    }
}

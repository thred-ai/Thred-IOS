//
//  CommentsVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-21.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import SDWebImage
import Firebase
import FirebaseFirestore

var uploadingComments = [String]()

class Comment{
    
    
    var timestamp: Date!
    var message: String!
    var timestampDiff: String!
    var commentID: String!
    var userInfo = UserInfo()
    
    
    init(timestamp: Date!, message: String!, commentID: String!, userInfo: UserInfo) {
        self.timestamp = timestamp
        self.message = message
        self.commentID = commentID
        self.userInfo = userInfo
    }
    
    convenience init() {
        self.init(timestamp: nil, message: nil, commentID: nil, userInfo: UserInfo())
    }
}


class CommentsVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    
    

    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var bottomBarHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendTextBtn: UIButton!
    fileprivate var keyBoardHeight: CGFloat = 0
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bottomBarInnerView: UIView!
    var post: Product!
    var comments = [Comment]()
    var selectedUser: UserInfo!
    var loadedUsers = [UserInfo]()
    var selectedComment: Comment!

    @IBAction func sendText(_ sender: UIButton){
        
        guard let text = textView.text, !text.isEmpty else{return}
        sender.isEnabled = false
        guard let uid = userInfo.uid else{return}
        guard let postUID = post.userInfo.uid else{return}
        let commentInServer = Firestore.firestore().collection("Users/" + postUID + "/Products/" + post.productID + "/Comments").document()

        let data = [
            
            "product_id" : post.productID,
            "creator_uid" : postUID,
            "uid" : uid,
            "is_adding" : true,
            "message" : text,
            "tagged" : [],
            "comment_id" : commentInServer.documentID
            
        ] as [String : Any]
        
        let comment = Comment(timestamp: Date(), message: text, commentID: commentInServer.documentID, userInfo: userInfo)
        self.comments.insert(comment, at: 0)
        uploadingComments.append(commentInServer.documentID)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.performBatchUpdates({
            tableView.insertRows(at: [indexPath], with: .none)
        }, completion: { finished in
            if finished{
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        })
        
        
        textView.text.removeAll()
        textViewDidChange(textView)
        
        sender.isEnabled = true
        
        checkAuthStatus {
            Functions.functions().httpsCallable("updateComment").call(data, completion: { result, error in
                uploadingComments.removeAll(where: {$0 == commentInServer.documentID})
                if let index = self.comments.firstIndex(where: {$0.commentID == commentInServer.documentID}){
                    self.tableView.performBatchUpdates({
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }, completion: nil)
                }
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                    self.post.comments += 1
                    print(result ?? "")
                }
            })
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        textView.resignFirstResponder()
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        initialWidth = textView.frame.width
        initialHeight = textView.frame.height
        previousHeight = textView.frame.height
        textViewDidChange(textView)
        bottomBarInnerView.layer.cornerRadius = bottomBarInnerView.frame.height / 2
        bottomBarInnerView.clipsToBounds = true
        bottomBarInnerView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        bottomBarInnerView.layer.borderWidth = 1.5
        setPlaceholder(textView: textView, textColor: ColorCompatibility.tertiaryLabel)
        view.addSubview(taggingTableView)
        taggingTableView.isHidden = true
        
        if selectedComment != nil{
            self.comments.append(selectedComment)
            DispatchQueue.main.async {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        
        isLoading = true
        guard let userUID = userInfo.uid else{return}
        checkAuthStatus {
            self.refreshLists(userUID: userUID){
                self.getComments(isRefreshing: true){
                    self.isLoading = false
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        initialWidth = textView.frame.width
        initialHeight = textView.frame.height
        previousHeight = textView.frame.height
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tableView{
            return UITableView.automaticDimension
        }
        else{
            return 55
        }
    }
    
    var isLoading = false
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height){
            print("fromScroll")
            if !self.isLoading{
                self.isLoading = true
                self.getComments(isRefreshing: false){
                    self.isLoading = false
                }
            }
        }
    }
    
    var lastDocument: DocumentSnapshot!
    
    func getComments(isRefreshing: Bool, completed: @escaping () -> ()){
        
        var query: Query! = nil
        guard let postUID = post.userInfo.uid else{completed(); return}

        if isRefreshing{
            query = Firestore.firestore().collection("Users").document(postUID).collection("Products/\(post.productID)/Comments").limit(to: 15).order(by: "Timestamp", descending: false)
        }
        else{
            guard let last = lastDocument else{return}
            query = Firestore.firestore().collection("Users").document(postUID).collection("Products/\(post.productID)/Comments").limit(to: 15).order(by: "Timestamp", descending: false).start(afterDocument: last)
        }
        query.getDocuments(completion: { (snapDocuments, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completed()
                return
            }
            else{
                if snapDocuments?.isEmpty ?? true{
                    completed()
                }
                else{
                    guard let snaps = snapDocuments?.documents else
                    {return}
                    self.lastDocument = snaps.last
                    for snap in snaps{
                        
                        let uid = snap["UID"] as! String
                        if self.comments.contains(where: {$0.commentID == snap.documentID}) || (userInfo.usersBlocking.contains(uid)){
                            continue
                        }
                        let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                        let message = snap["Message"] as? String
                        let userInfo = UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil)
                        
                        self.comments.append(Comment(timestamp: timestamp, message: message, commentID: snap.documentID, userInfo: userInfo))
                        
                        self.tableView.performBatchUpdates({
                            self.tableView.insertRows(at: [IndexPath(row: self.comments.count - 1, section: 0)], with: .none)
                        }, completion: { finished in
                            if finished{
                                if snap == snaps.last{
                                    completed()
                                }
                            }
                        })
                    }
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView{
            return comments.count
        }
        else{
            return loadedUsers.count
        }
    }
    
    var downloadingProfiles = [String]()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView{
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentCell
            cell?.backgroundColor = ColorCompatibility.systemBackground
            let comment = comments[indexPath.row]
            cell?.comment = comment
            cell?.fullNameLbl.text = nil
            cell?.usernameLbl.text = nil
            cell?.profilePicture.image = nil
            cell?.spinner.isHidden = true
            if let attr = cell?.messageView.attributedText.mutableCopy() as? NSMutableAttributedString{
                attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
                attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: cell?.messageView.font?.pointSize ?? 16)!], range: NSMakeRange(0, attr.length))
                cell?.messageView.attributedText = attr
            }
            cell?.messageView.text = nil
            cell?.alpha = 1.0
            guard let uid = comment.userInfo.uid else{return cell!}
            guard let userUID = userInfo.uid else{return cell!}
            cell?.vc = self
            cell?.messageView.text = comment.message
            cell?.messageView.addLinks(isNotification: false)
            tableView.checkCommentTimes(comment: comment, timestampLbl: cell?.timestampLbl)

            if comment.userInfo.usersBlocking.contains(userUID){
                cell?.alpha = 0.2
            }
            if uploadingComments.contains(comment.commentID){
                cell?.spinner.isHidden = false
                cell?.spinner.animate()
            }
            
            if comment.userInfo.username != nil{
                cell?.fullNameLbl.text = comment.userInfo.fullName ?? "null"
                cell?.usernameLbl.text = "@\(comment.userInfo.username ?? "null")"
                if let dp = comment.userInfo.dp{
                    cell?.profilePicture.image = UIImage(data: dp)
                }
            }
            else{
                switch comments.compactMap({$0.userInfo}).first(where: {$0.uid == uid}){
                case let same:
                    if same?.username != nil, same?.dp != nil{
                        if same != nil{
                            comment.userInfo.username = same?.username
                            comment.userInfo.fullName = same?.fullName
                            comment.userInfo.dpID = same?.dpID
                            comment.userInfo.bio = same?.bio
                            comment.userInfo.dp = same?.dp
                            comment.userInfo.usersBlocking = same?.usersBlocking ?? []
                            cell?.fullNameLbl.text = comment.userInfo.fullName ?? "null"
                            cell?.usernameLbl.text = "@\(comment.userInfo.username ?? "null")"
                            if let dp = comment.userInfo.dp{
                                cell?.profilePicture.image = UIImage(data: dp)
                            }
                        }
                        else{
                            fallthrough
                        }
                    }
                    else{
                        fallthrough
                    }
                default:
                    if !downloadingProfiles.contains(uid){
                        downloadingProfiles.append(uid)
                        self.downloadUserInfo(uid: uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: comment.userInfo, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, img, userFollowing, usersBlocking, postCount, followersCount, followingCount, profileLink  in
                            self.downloadingProfiles.removeAll(where: {$0 == uid})
                            
                            if usersBlocking.contains(userUID){
                                cell?.alpha = 0.2
                            }
                            comment.userInfo.username = username ?? "null"
                            comment.userInfo.fullName = fullName ?? "null"
                            comment.userInfo.dpID = dpUID
                            comment.userInfo.bio = bio
                            comment.userInfo.dp = img
                            comment.userInfo.usersBlocking = usersBlocking
                            comment.userInfo.postCount = postCount
                            comment.userInfo.followerCount = followersCount
                            comment.userInfo.followingCount = followingCount
                            comment.userInfo.profileLink = profileLink

                            cell?.fullNameLbl.text = fullName ?? "null"
                            cell?.usernameLbl.text = "@\(username ?? "null")"
                            
                            if let dp = comment.userInfo.dp{
                                cell?.profilePicture.image = UIImage(data: dp)
                            }
                            
                            if let indices = tableView.indexPathsForVisibleRows{
                                for index in indices{
                                    if self.comments[index.row].userInfo.uid == uid{
                                        if let cell = tableView.cellForRow(at: index){
                                            switch cell{
                                            case let c as CommentCell:
                                                c.fullNameLbl.text = fullName
                                                c.usernameLbl.text = "@" + (username ?? "null")
                                                if let dp = comment.userInfo.dp{
                                                    c.profilePicture.image = UIImage(data: dp)
                                                }
                                            default:
                                                continue
                                            }
                                        }
                                    }
                                }
                            }
                        })
                    }
                }
            }
            return cell!
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as? SearchUserTableViewCell
            let user = self.loadedUsers[indexPath.row]
            cell?.userImageView.image = nil

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
            return cell!
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.hideCenterBtn()
        setKeyBoardNotifs()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        textView.becomeFirstResponder()
        if selectedComment != nil{
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)){
                UIView.animate(withDuration: 0.25, animations: {
                    cell.backgroundColor = ColorCompatibility.tertiarySystemGroupedBackground
                })
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
                self.tableView.contentInset.bottom = 0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0
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
                        self.tableView.contentInset.bottom = keyboardHeight - bottomPadding
                        self.tableView.verticalScrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
                    }, completion: { finished in
                        if finished{}
                    })
                }
            }
        }
    }
    
    
    
    var initialWidth = CGFloat()
    var initialHeight = CGFloat()
    var previousHeight = CGFloat()
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
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

        if let lastText = textView.text.components(separatedBy: " ").last{
            if lastText.starts(with: "@"){
                let username = String(lastText.dropFirst())
                searchTaggingView(searchText: username)
            }
            else{
                if !taggingTableView.isHidden{
                    setTag(index: nil)
                    resetTaggingTableView()
                }
            }
        }
        else{
            if !taggingTableView.isHidden{
                resetTaggingTableView()
            }
        }
    }
    
    
    
    func searchTaggingView(searchText: String){
        
        
        if self.taggingTableView.isHidden{
            self.taggingTableView.isHidden = false
            self.taggingTableView.frame.origin.y = bottomBar.frame.origin.y + bottomBar.transform.ty
            let height = bottomBar.frame.origin.y - 45
            print(height)
            
            
            self.taggingTableView.frame.size.height = height
            
            UIView.animate(withDuration: 0.2, animations: {
                self.taggingTableView.frame.origin.y = 45
            })
        }
        
        if searchText == ""{
            loadedUsers.removeAll()
            taggingTableView.reloadData()
            //self.getFollowers()
        }
        else{
            //searchBar.isLoading = true
            let lowerCaseSearchText = searchText.lowercased()
            Firestore.firestore().collection("Users").whereField("Username", isGreaterThanOrEqualTo: lowerCaseSearchText).whereField("Username", isLessThanOrEqualTo: lowerCaseSearchText + "\u{f8ff}").limit(to: 8).getDocuments(completion: { query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    guard let userUID = userInfo.uid else{return}
                    self.loadedUsers.removeAll()
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{
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
                                let profileLink = URL(string: (document["ProfileLink"] as? String) ?? "")

                                if usersBlocking?.contains(userUID) ?? false{
                                    continue
                                }
                                
                                let user = UserInfo(uid: uid, dp: nil, dpID: dpLink, username: username, fullName: fullname, bio: bio, notifID: nil, userFollowing: userFollowing ?? [], userLiked: [], followerCount: followerCount ?? 0, postCount: postCount ?? 0, followingCount: followingCount ?? 0, usersBlocking: usersBlocking ?? [], profileLink: profileLink)

                                self.loadedUsers.append(user)
                                self.taggingTableView.reloadData()
                                
                                if uid == userInfo.uid{
                                    user.dp = userInfo.dp
                                    user.dpID = userInfo.dpID
                                    continue
                                }
                                let infoMapped = self.comments.compactMap({$0.userInfo})
                                
                                if let same = infoMapped.first(where: {$0.uid == uid}), let dp = same.dp, let dpID = same.dpID{
                                    user.dp = dp
                                    user.dpID = dpID
                                    continue
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
                                                if let index = self.loadedUsers.firstIndex(where: {$0.uid == uid}){
                                                    self.taggingTableView.performBatchUpdates({
                                                        self.taggingTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                                    }, completion: nil)
                                                }
                                            }
                                        })
                                    }
                                })
                            }
                        }
                        else{
                            self.taggingTableView.reloadData() //No Results
                        }
                    }
                }
            })
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView == self.tableView{
            if(velocity.y < 0) {
                print("Hide")
                if self.textView.isFirstResponder{
                    self.textView.resignFirstResponder()
                }
            } else {
                print("Unhide")
            }
        }
    }
    
    lazy var taggingTableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect(x: 0, y: bottomBar.frame.origin.y, width: view.frame.width, height: 100))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.95)
        tableView.register(UINib(nibName: "SearchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "search")
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == taggingTableView{
            setTag(index: indexPath.row)
            resetTaggingTableView()
        }
    }
    
    func setTag(index: Int?){
        var components = textView.text.components(separatedBy: " ")
        guard !components.isEmpty else{return}
        
        if let index = index{
            guard let username = loadedUsers[index].username else{return}
            components.removeLast()
            components.append("@\(username)")
            textView.text.removeAll()
            for component in components{
                textView.text.append("\(component) ")
            }
        }
    }
    
    func resetTaggingTableView(){
        loadedUsers.removeAll()
        taggingTableView.reloadData()
        taggingTableView.isHidden = true
    }
    
    var placeholderLabel = UILabel()

    
    func setPlaceholder(textView: UITextView, textColor: UIColor?){
        
        
        placeholderLabel.text = "Say something..."
        placeholderLabel.font = UIFont(name: "NexaW01-Regular", size: 15)
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if tableView == self.tableView{
            if self.comments[indexPath.row].userInfo.uid == userInfo.uid || self.post.userInfo.uid == userInfo.uid{
                return true
            }
        }
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            
            let comment = self.comments[indexPath.row]
            guard let message = self.comments[indexPath.row].message else{return}
            self.comments.remove(at: indexPath.row)
            DispatchQueue.main.async {
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }, completion: nil)
            }
            deleteComment(comment: comment, message: message)
        }
    }
    
    func deleteComment(comment: Comment, message: String){
        
        guard let commentUID = comment.userInfo.uid else{return}
        guard let commentID = comment.commentID else{return}
        guard let postUID = post.userInfo.uid else{return}

        let data = [
            
            "product_id" : post.productID,
            "creator_uid" : postUID,
            "uid" : commentUID,
            "message" : message,
            "is_adding" : false,
            "tagged" : [],
            "comment_id" : commentID
            
        ] as [String : Any]
        checkAuthStatus {
            Functions.functions().httpsCallable("updateComment").call(data, completion: { result, error in
                if let err = error{
                    print(err.localizedDescription)
                }
                else{
                    self.post.comments -= 1
                    print(result ?? "")
                }
            })
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let friendVC = segue.destination as? FriendVC{
            friendVC.friendInfo = selectedUser
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}

